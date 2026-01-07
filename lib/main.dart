import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize().then((InitializationStatus status) {
    print('AdMob SDK initialized: $status');
  }).catchError((error) {
    print('AdMob SDK initialization failed: $error');
  });
  runApp(const CUCHDPortalApp());
}

class CUCHDPortalApp extends StatelessWidget {
  const CUCHDPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CUCHD Portal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const WebViewScreen(),
    const MarksCalculatorScreen(),
    const CGPACalculatorScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print('HomeScreen: App resumed, reinitializing AdMob SDK...');
      MobileAds.instance.initialize().then((InitializationStatus status) {
        print('HomeScreen: AdMob SDK reinitialized: $status');
      }).catchError((error) {
        print('HomeScreen: AdMob SDK reinitialization failed: $error');
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CUCHD Portal')),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.web), label: 'Portal'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Marks Calculator'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'CGPA Calculator'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _isLoading = true;
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  final String _bannerAdUnitId = 'ca-app-pub-6731497556275026/5914492412'; // Test banner ID
  final String _rewardedAdUnitId = 'ca-app-pub-6731497556275026/3108698819'; // Test rewarded ID

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _isLoading = true),
        onPageFinished: (_) => setState(() => _isLoading = false),
        onWebResourceError: (error) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.description}')),
        ),
      ))
      ..loadRequest(Uri.parse('https://students.cuchd.in/'));

    _loadBannerAd();
    _loadRewardedAd();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print('WebViewScreen: App resumed, reloading ads...');
      if (!_isBannerAdReady) _loadBannerAd();
      if (!_isRewardedAdReady) _loadRewardedAd();
    }
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          print('WebViewScreen: Banner Ad loaded successfully');
          setState(() => _isBannerAdReady = true);
        },
        onAdFailedToLoad: (ad, error) {
          print('WebViewScreen: Banner Ad failed to load: $error');
          ad.dispose();
          setState(() => _isBannerAdReady = false);
          Future.delayed(const Duration(seconds: 5), () {
            if (!_isBannerAdReady && mounted) _loadBannerAd();
          });
        },
      ),
    )..load();
  }

  void _loadRewardedAd() {
    print('WebViewScreen: Attempting to load rewarded ad...');
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('WebViewScreen: Rewarded Ad loaded successfully');
          setState(() {
            _rewardedAd = ad;
            _isRewardedAdReady = true;
          });
        },
        onAdFailedToLoad: (error) {
          print('WebViewScreen: Rewarded Ad failed to load: $error');
          setState(() {
            _rewardedAd = null;
            _isRewardedAdReady = false;
          });
          Future.delayed(const Duration(seconds: 5), () {
            if (!_isRewardedAdReady && mounted) _loadRewardedAd();
          });
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_isRewardedAdReady && _rewardedAd != null) {
      print('WebViewScreen: Rewarded Ad is available. Attempting to show...');
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          print('WebViewScreen: Rewarded Ad dismissed. Disposing and reloading.');
          ad.dispose();
          setState(() {
            _rewardedAd = null;
            _isRewardedAdReady = false;
          });
          _loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('WebViewScreen: Rewarded Ad failed to show: $error');
          ad.dispose();
          setState(() {
            _rewardedAd = null;
            _isRewardedAdReady = false;
          });
          _loadRewardedAd();
        },
      );

      _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your support!')),
        );
      });
    } else {
      print('WebViewScreen: Rewarded ad not loaded yet.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rewarded ad not loaded yet.')),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: _showRewardedAd,
          child: const Text('Do not click on this button'),
        ),
        if (_isBannerAdReady && _bannerAd != null)
          Container(
            alignment: Alignment.center,
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        if (!_isBannerAdReady)
          const Text('Banner ad not loaded', style: TextStyle(color: Colors.red)),
      ],
    );
  }
}

class MarksCalculatorScreen extends StatefulWidget {
  const MarksCalculatorScreen({super.key});

  @override
  _MarksCalculatorScreenState createState() => _MarksCalculatorScreenState();
}

class _MarksCalculatorScreenState extends State<MarksCalculatorScreen> with WidgetsBindingObserver {
  bool _isHybrid = false;
  final _formKey = GlobalKey<FormState>();
  double? _assignment, _attendance, _surpriseTest, _quiz, _mst1, _mst2, _end, _labMst;
  List<double?> _worksheets = List.filled(10, null);
  String? _result;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  final String _rewardedAdUnitId = 'ca-app-pub-6731497556275026/3108698819'; // Test rewarded ID

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRewardedAd();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print('MarksCalculatorScreen: App resumed, reloading ads...');
      if (!_isRewardedAdReady) _loadRewardedAd();
    }
  }

  void _loadRewardedAd() {
    print('MarksCalculatorScreen: Attempting to load rewarded ad...');
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('MarksCalculatorScreen: Rewarded Ad loaded successfully');
          setState(() {
            _rewardedAd = ad;
            _isRewardedAdReady = true;
          });
        },
        onAdFailedToLoad: (error) {
          print('MarksCalculatorScreen: Rewarded Ad failed to load: $error');
          setState(() {
            _rewardedAd = null;
            _isRewardedAdReady = false;
          });
          Future.delayed(const Duration(seconds: 5), () {
            if (!_isRewardedAdReady && mounted) _loadRewardedAd();
          });
        },
      ),
    );
  }

  void _showRewardedAdThenCalculate() {
    print('MarksCalculatorScreen: Calculate button pressed. _rewardedAd is currently: $_rewardedAd');
    if (_isRewardedAdReady && _rewardedAd != null) {
      print('MarksCalculatorScreen: Rewarded Ad is available. Attempting to show...');
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          print('MarksCalculatorScreen: Rewarded Ad dismissed. Disposing and reloading.');
          ad.dispose();
          setState(() {
            _rewardedAd = null;
            _isRewardedAdReady = false;
          });
          _loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('MarksCalculatorScreen: Rewarded Ad failed to show: $error');
          ad.dispose();
          setState(() {
            _rewardedAd = null;
            _isRewardedAdReady = false;
          });
          _calculateMarks();
        },
      );

      _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        print('MarksCalculatorScreen: User earned reward. Calculating marks...');
        _calculateMarks();
      });
    } else {
      print('MarksCalculatorScreen: Rewarded Ad not available. Calculating marks directly.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad not ready. Calculating marks directly.')),
      );
      _calculateMarks();
    }
  }

  void _calculateMarks() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      double total;
      if (_isHybrid) {
        double s = (_surpriseTest! / 12) * 4;
        double n = (_labMst! / 10) * 15;
        double worksheetTotal = _worksheets.fold(0.0, (sum, item) => sum! + (item ?? 0.0));
        double worksheet = (worksheetTotal / 300) * 45;
        double m = (_mst1! + _mst2!) / 2;
        total = ((_assignment! + _quiz! + m + _attendance! + s + worksheet + _end! + n) / 140) * 70;
      } else {
        double s = (_surpriseTest! / 12) * 4;
        double m = (_mst1! + _mst2!) / 2;
        total = _assignment! + _quiz! + m + _attendance! + s;
      }
      setState(() {
        _result = total.toStringAsFixed(2);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Marks Calculator', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Row(
              children: [
                const Text('Course Type: '),
                Radio<bool>(
                  value: false,
                  groupValue: _isHybrid,
                  onChanged: (v) => setState(() => _isHybrid = v!),
                ),
                const Text('Regular'),
                Radio<bool>(
                  value: true,
                  groupValue: _isHybrid,
                  onChanged: (v) => setState(() => _isHybrid = v!),
                ),
                const Text('Hybrid'),
              ],
            ),
            _buildTextField('Assignment Marks', (v) => _assignment = double.tryParse(v ?? '')),
            _buildTextField('Attendance Marks', (v) => _attendance = double.tryParse(v ?? '')),
            _buildTextField('Surprise Test Marks (out of 12)', (v) => _surpriseTest = double.tryParse(v ?? '')),
            _buildTextField('Quiz Marks', (v) => _quiz = double.tryParse(v ?? '')),
            _buildTextField('MST 1 Marks', (v) => _mst1 = double.tryParse(v ?? '')),
            _buildTextField('MST 2 Marks', (v) => _mst2 = double.tryParse(v ?? '')),
            if (_isHybrid) ...[
              _buildTextField('End Sem Practical Marks', (v) => _end = double.tryParse(v ?? '')),
              _buildTextField('Lab MST Marks (out of 10)', (v) => _labMst = double.tryParse(v ?? '')),
              ...List.generate(10, (i) => _buildTextField('Worksheet ${i + 1}', (v) => _worksheets[i] = double.tryParse(v ?? ''))),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showRewardedAdThenCalculate,
              child: const Text('Calculate'),
            ),
            if (_result != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text('Internal Marks: $_result', style: const TextStyle(fontSize: 18)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, FormFieldSetter<String?> onSaved) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (double.tryParse(v) == null) return 'Invalid number';
        return null;
      },
      onSaved: onSaved,
    );
  }
}

class SubjectData {
  int? credits;
  String? grade;

  SubjectData({this.credits, this.grade});
}

class CGPACalculatorScreen extends StatefulWidget {
  const CGPACalculatorScreen({super.key});

  @override
  _CGPACalculatorScreenState createState() => _CGPACalculatorScreenState();
}

class _CGPACalculatorScreenState extends State<CGPACalculatorScreen> with WidgetsBindingObserver {
  final List<SubjectData> _subjects = [SubjectData(credits: 4, grade: 'A+')];
  final List<GlobalKey<FormState>> _formKeys = [GlobalKey<FormState>()];
  String? _cgpaResult;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  final String _rewardedAdUnitId = 'ca-app-pub-6731497556275026/3108698819'; // Test rewarded ID

  final Map<String, double> _gradePoints = {
    'A+': 10.0,
    'A': 9.0,
    'B+': 8.0,
    'B': 7.0,
    'C+': 6.0,
    'C': 5.0,
    'D': 4.0,
    'F': 0.0,
  };

  final List<int> _availableCredits = [1, 2, 3, 4, 5, 6, 7];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRewardedAd();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print('CGPACalculatorScreen: App resumed, reloading ads...');
      if (!_isRewardedAdReady) _loadRewardedAd();
    }
  }

  void _loadRewardedAd() {
    print('CGPACalculatorScreen: Attempting to load rewarded ad...');
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('CGPACalculatorScreen: Rewarded Ad loaded successfully');
          setState(() {
            _rewardedAd = ad;
            _isRewardedAdReady = true;
          });
        },
        onAdFailedToLoad: (error) {
          print('CGPACalculatorScreen: Rewarded Ad failed to load: $error');
          setState(() {
            _rewardedAd = null;
            _isRewardedAdReady = false;
          });
          Future.delayed(const Duration(seconds: 5), () {
            if (!_isRewardedAdReady && mounted) _loadRewardedAd();
          });
        },
      ),
    );
  }

  void _showRewardedAdThenCalculateCGPA() {
    print('CGPACalculatorScreen: Calculate button pressed. _rewardedAd is currently: $_rewardedAd');
    if (_isRewardedAdReady && _rewardedAd != null) {
      print('CGPACalculatorScreen: Rewarded Ad is available. Attempting to show...');
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          print('CGPACalculatorScreen: Rewarded Ad dismissed. Disposing and reloading.');
          ad.dispose();
          setState(() {
            _rewardedAd = null;
            _isRewardedAdReady = false;
          });
          _loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('CGPACalculatorScreen: Rewarded Ad failed to show: $error');
          ad.dispose();
          setState(() {
            _rewardedAd = null;
            _isRewardedAdReady = false;
          });
          _calculateCgpa();
        },
      );

      _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        print('CGPACalculatorScreen: User earned reward. Calculating CGPA...');
        _calculateCgpa();
      });
    } else {
      print('CGPACalculatorScreen: Rewarded Ad not available. Calculating CGPA directly.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad not ready. Calculating CGPA directly.')),
      );
      _calculateCgpa();
    }
  }

  void _addSubject() {
    setState(() {
      _subjects.add(SubjectData(credits: 4, grade: 'A+'));
      _formKeys.add(GlobalKey<FormState>());
      _cgpaResult = null;
    });
  }

  void _removeSubject(int index) {
    setState(() {
      _subjects.removeAt(index);
      _formKeys.removeAt(index);
      _cgpaResult = null;
    });
  }

  void _calculateCgpa() {
    double totalWeightedPoints = 0.0;
    double totalCredits = 0.0;
    bool isValid = true;

    for (var i = 0; i < _formKeys.length; i++) {
      if (!_formKeys[i].currentState!.validate()) {
        isValid = false;
        break;
      }
      _formKeys[i].currentState!.save();
    }

    if (isValid) {
      for (var subject in _subjects) {
        if (subject.credits != null && subject.grade != null) {
          final double? gradePoint = _gradePoints[subject.grade];
          if (gradePoint != null) {
            totalWeightedPoints += (subject.credits! * gradePoint);
            totalCredits += subject.credits!;
          }
        }
      }

      setState(() {
        if (totalCredits > 0) {
          _cgpaResult = (totalWeightedPoints / totalCredits).toStringAsFixed(2);
        } else {
          _cgpaResult = 'N/A (Add subjects with credits)';
        }
      });
    } else {
      setState(() {
        _cgpaResult = 'Please select credits and grades for all subjects.';
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CGPA Calculator', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(flex: 1, child: Text('S.no', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('CREDITS', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('GRADES', style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 40),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _subjects.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Form(
                      key: _formKeys[index],
                      child: Row(
                        children: [
                          Expanded(flex: 1, child: Text('${index + 1}')),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int>(
                              value: _subjects[index].credits,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: _availableCredits.map((int credit) {
                                return DropdownMenuItem<int>(
                                  value: credit,
                                  child: Text('$credit'),
                                );
                              }).toList(),
                              onChanged: (int? newValue) {
                                setState(() {
                                  _subjects[index].credits = newValue;
                                });
                              },
                              onSaved: (int? value) {
                                _subjects[index].credits = value;
                              },
                              validator: (value) => value == null ? 'Req' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _subjects[index].grade,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: _gradePoints.keys.map((String grade) {
                                return DropdownMenuItem<String>(
                                  value: grade,
                                  child: Text(grade),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _subjects[index].grade = newValue;
                                });
                              },
                              onSaved: (String? value) {
                                _subjects[index].grade = value;
                              },
                              validator: (value) => value == null ? 'Req' : null,
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _removeSubject(index),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _addSubject,
            icon: const Icon(Icons.add),
            label: const Text('Add Subject'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _showRewardedAdThenCalculateCGPA,
            child: const Text('Calculate CGPA'),
          ),
          if (_cgpaResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text('Your CGPA: $_cgpaResult', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}