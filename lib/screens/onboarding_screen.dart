import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final List<String> _questions = [
    'What are three areas of your life you\'d  to improve?',
    'Describe a personal goal you\'d like to achieve in the next year.',
    'What activities make you feel most fulfilled?'
  ];
  List<String> _responses = ['', '', ''];
  int _currentQuestionIndex = 0;

  // Animation
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // Text Editing Controller
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize AnimationController
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    // Start the animation
    _controller.forward();

    // Initialize the text controller with the first response
    _textController.text = _responses[_currentQuestionIndex];
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    if (_formKey.currentState?.validate() ?? false) {
      // Save the current response
      _responses[_currentQuestionIndex] = _textController.text;

      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _textController.text = _responses[_currentQuestionIndex];
        });
        _controller.reset();
        _controller.forward();
      } else {
        // All questions answered, navigate to quest screen
        Navigator.pushNamed(context, '/quest', arguments: {
          'responses': _responses,
        });
      }
    }
  }

  void _previousQuestion() {
    // Save the current response
    _responses[_currentQuestionIndex] = _textController.text;

    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _textController.text = _responses[_currentQuestionIndex];
      });
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Questly Onboarding'),
        leading: _currentQuestionIndex > 0
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: _previousQuestion,
              )
            : null,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _questions.length,
                  backgroundColor: Colors.grey[300],
                  color: Colors.blue,
                ),
                SizedBox(height: 20),
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 20),
                Text(
                  _questions[_currentQuestionIndex],
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: TextFormField(
                    controller: _textController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Your answer',
                    ),
                    maxLines: null,
                    validator: (value) {
                      return (value == null || value.isEmpty)
                          ? 'Please enter your response'
                          : null;
                    },
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _currentQuestionIndex > 0
                        ? ElevatedButton(
                            child: Text('Back'),
                            onPressed: _previousQuestion,
                          )
                        : SizedBox(width: 0), // Placeholder to align the button
                    ElevatedButton(
                      child: Text(
                        _currentQuestionIndex < _questions.length - 1
                            ? 'Next'
                            : 'Finish',
                      ),
                      onPressed: _nextQuestion,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
