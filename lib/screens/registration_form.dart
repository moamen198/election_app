import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final nameController = TextEditingController();
  final birthdateController = TextEditingController();
  final phoneController = TextEditingController();
  final voterNumberController = TextEditingController();
  final familyNumberController = TextEditingController();
  final registerCenterController = TextEditingController();
  final stationInfoController = TextEditingController();

  Uint8List? _cardImage;
  Uint8List? _personImage;
  String selectedGovernorate = 'الأنبار';

  final List<String> governorates = [
    'الأنبار', 'بغداد', 'البصرة', 'دهوك', 'القادسية', 'ديالى', 'ذي قار',
    'السليمانية', 'صلاح الدين', 'كركوك', 'كربلاء', 'المثنى', 'النجف',
    'نينوى', 'واسط', 'ميسان', 'بابل', 'أربيل'
  ];

  List<bool> fingerprints = [false, false, false, false];

  late html.VideoElement _video;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  void _startCamera() async {
    _video = html.VideoElement()
      ..autoplay = true
      ..style.display = 'none';

    final stream = await html.window.navigator.mediaDevices!
        .getUserMedia({'video': {'facingMode': 'user'}});

    _video.srcObject = stream;
    html.document.body!.append(_video);
  }

  void _captureImage(bool isCard) async {
    final canvas = html.CanvasElement(width: _video.videoWidth, height: _video.videoHeight);
    final ctx = canvas.context2D;
    ctx.drawImage(_video, 0, 0);
    final blob = await canvas.toBlob('image/png');
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob!);
    await reader.onLoad.first;

    setState(() {
      if (isCard) {
        _cardImage = reader.result as Uint8List;
      } else {
        _personImage = reader.result as Uint8List;
      }
    });
  }

  void _analyzeImage() async {
    if (_cardImage == null) return;
    final base64 = base64Encode(_cardImage!);
    const apiKey = 'AIzaSyDrpLy_Cob-YIDK6RwAUZkW2teGk5kyPUg';
    final url = Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$apiKey');

    final body = jsonEncode({
      "requests": [
        {
          "image": {"content": base64},
          "features": [
            {"type": "DOCUMENT_TEXT_DETECTION"}
          ],
          "imageContext": {
            "languageHints": ["ar"]
          }
        }
      ]
    });

    final response = await http.post(url, body: body, headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      final text = result['responses'][0]['fullTextAnnotation']['text'] ?? '';
      _mapExtractedTextToFields(text);
    }
  }

  void _mapExtractedTextToFields(String text) {
    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final excludeKeywords = ['المفوضية', 'العليا', 'المستقلة', 'للانتخابات', 'جمهورية العراق', 'بطاقة', 'الناخب'];
    final hasKurdish = RegExp(r'[ەێۆچڤڤە]');

    setState(() {
      for (final line in lines) {
        if (excludeKeywords.any((k) => line.contains(k)) || hasKurdish.hasMatch(line)) continue;
        if (line.contains('الاسم الثلاثي')) {
          nameController.text = line.replaceAll('الاسم الثلاثي', '').trim();
        } else if (RegExp(r'\d{4}/\d{2}/\d{2}').hasMatch(line)) {
          birthdateController.text = line;
        } else if (RegExp(r'\b\d{8}\b').hasMatch(line)) {
          voterNumberController.text = RegExp(r'\b\d{8}\b').stringMatch(line) ?? '';
        } else if (RegExp(r'\b\d{6}\b').hasMatch(line)) {
          familyNumberController.text = RegExp(r'\b\d{6}\b').stringMatch(line) ?? '';
        } else if (RegExp(r'\b\d{3,4}\b').hasMatch(line)) {
          registerCenterController.text = RegExp(r'\b\d{3,4}\b').stringMatch(line) ?? '';
        } else if (line.contains('مدرسة') || line.contains('معهد')) {
          stationInfoController.text = line;
        }
      }
    });
  }

  void _submitToAPI() async {
    final url = Uri.parse('https://dev-moamen.pro/test/voters.php');
    final response = await http.post(url, body: {
      'name': nameController.text,
      'birthdate': birthdateController.text,
      'phone': phoneController.text,
      'voter_number': voterNumberController.text,
      'family_number': familyNumberController.text,
      'register_center': registerCenterController.text,
      'station_info': stationInfoController.text,
      'governorate': selectedGovernorate,
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال البيانات بنجاح')));
    }
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  void _startFingerprintSequence() {
    int index = 0;
    Future.doWhile(() async {
      if (index >= 4) return false;
      await Future.delayed(const Duration(seconds: 3));
      setState(() => fingerprints[index++] = true);
      return true;
    });
  }

  Widget _buildFingerprint(int index) {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: fingerprints[index] ? Colors.green : Colors.grey[800],
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white),
      ),
      child: const Icon(Icons.fingerprint, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('تحليل بطاقة الناخب')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_cardImage != null) Image.memory(_cardImage!, height: 200),
            ElevatedButton.icon(
              onPressed: () => _captureImage(true),
              icon: const Icon(Icons.credit_card),
              label: const Text('التقاط صورة البطاقة'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _analyzeImage,
              icon: const Icon(Icons.search),
              label: const Text('تحليل الصورة'),
            ),
            const SizedBox(height: 8),
            if (_personImage != null) Image.memory(_personImage!, height: 200),
            ElevatedButton.icon(
              onPressed: () => _captureImage(false),
              icon: const Icon(Icons.person),
              label: const Text('التقاط صورة الشخص'),
            ),
            const SizedBox(height: 24),
            _buildField('الاسم الثلاثي', nameController),
            _buildField('تاريخ الميلاد', birthdateController),
            _buildField('رقم الهاتف', phoneController),
            _buildField('رقم الناخب', voterNumberController),
            DropdownButtonFormField<String>(
              value: selectedGovernorate,
              decoration: const InputDecoration(
                labelText: 'المحافظة',
                filled: true,
                fillColor: Colors.white10,
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
              ),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(color: Colors.white),
              dropdownColor: Colors.black,
              items: governorates.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (val) => setState(() => selectedGovernorate = val!),
            ),
            const SizedBox(height: 12),
            _buildField('رقم العائلة', familyNumberController),
            _buildField('مركز التسجيل', registerCenterController),
            _buildField('اسم مركز الاقتراع', stationInfoController),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _startFingerprintSequence,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, _buildFingerprint),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _submitToAPI,
              icon: const Icon(Icons.send),
              label: const Text('إرسال البيانات'),
            ),
          ],
        ),
      ),
    );
  }
}