import 'package:flutter/material.dart';
import 'package:chahanjan_app/screens/chat_screen.dart';

class MeetingProposalModal extends StatefulWidget {
  final String receiverNickname;
  final Function(String message, String placeName, int estimatedCost, DateTime meetingTime, double proposerRatio) onSend;
  final VoidCallback? onGift; // Callback for gifting coffee

  const MeetingProposalModal({
    super.key,
    required this.receiverNickname,
    required this.onSend,
    this.onGift,
  });

  @override
  State<MeetingProposalModal> createState() => _MeetingProposalModalState();
}

class _MeetingProposalModalState extends State<MeetingProposalModal> {
  // ... existing state ...

  final _messageController = TextEditingController();
  final _placeController = TextEditingController();
  final _costController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  double _proposerRatio = 0.5; // Default: Half-Half
  bool _isSuccess = false; // Track if proposal was sent successfully

  @override
  void initState() {
    super.initState();
    _placeController.text = 'Starbucks Gangnam'; // Default placeholder
  }

  @override
  void dispose() {
    _messageController.dispose();
    _placeController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _handleSend() async {
    final message = _messageController.text;
    final placeName = _placeController.text;
    final costString = _costController.text;
    final estimatedCost = int.tryParse(costString) ?? 0;

    // 1. Validation
    if (estimatedCost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount!'), // "금액을 입력해주세요!"
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (placeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a meeting place.')),
      );
      return;
    }

    final meetingTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // 2. Data Collection & Logging (Mock)
    // Assuming sender_id is 1 (Me) for this mock, or passed in. 
    // Since we are in the modal, we'll just log what we have.
    final proposalData = {
      'sender_id': 'CURRENT_USER_ID', // Replace with actual ID if available
      'receiver_id': widget.receiverNickname, // Using nickname as proxy for ID here
      'location': placeName,
      'meeting_time': meetingTime.toIso8601String(),
      'total_cost': estimatedCost,
      'split_ratio': _proposerRatio,
      'message': message,
    };

    debugPrint("📨 DB 저장 요청 (DB Save Request): $proposalData");

    try {
      await widget.onSend(message, placeName, estimatedCost, meetingTime, _proposerRatio);
      
      if (mounted) {
        setState(() {
          _isSuccess = true;
        });
        // Showing Toast as requested, but keeping the modal open for Chat Room entry
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proposal sent successfully!')), // "약속 제안을 보냈습니다!"
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send proposal: $e')),
        );
      }
    }
  }

  void _navigateToChat() {
    Navigator.pop(context); // Close modal
    
    // Generate a chat ID (simple implementation)
    // In a real app, you'd create the chat in Firestore first and get the ID
    // For now, we'll construct it deterministically or pass a placeholder
    final myId = 'CURRENT_USER_ID'; // TODO: Get from provider
    final partnerId = widget.receiverNickname; // Using nickname as ID proxy as per current logic
    
    // Sort IDs to ensure consistency
    final ids = [myId, partnerId]..sort();
    final chatId = ids.join('_');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          roomId: chatId,
          receiverNickname: widget.receiverNickname,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: _isSuccess ? _buildSuccessView() : _buildProposalForm(),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.check_circle, color: Colors.green, size: 80),
        const SizedBox(height: 16),
        const Text(
          'Proposal Sent Successfully!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'You can now chat with ${widget.receiverNickname}.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _navigateToChat,
            icon: const Icon(Icons.chat),
            label: const Text('Go to Chat Room 💬'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildProposalForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Safety Banner
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.red.shade50,
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚠️ 전화번호나 개인정보를 함부로 알려주지 마세요!',
                  style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Propose to ${widget.receiverNickname}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        
        // Date & Time Picker
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    "${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}",
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => _selectTime(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(
                    _selectedTime.format(context),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Place Name
        TextField(
          controller: _placeController,
          decoration: const InputDecoration(
            labelText: 'Meeting Place',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
        const SizedBox(height: 16),

        // Estimated Cost
        TextField(
          controller: _costController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Estimated Cost (KRW)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money),
            suffixText: 'KRW',
          ),
        ),
        const SizedBox(height: 16),

        // Cost Sharing Buttons
        const Text(
          'Cost Sharing',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRatioButton('I Pay', 1.0),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRatioButton('Half-Half', 0.5),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRatioButton('You Pay', 0.0),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Cost Breakdown Display
        Builder(
          builder: (context) {
            final cost = int.tryParse(_costController.text) ?? 0;
            final myCost = (cost * _proposerRatio).round();
            final partnerCost = (cost * (1 - _proposerRatio)).round();
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Me: $myCost KRW', style: const TextStyle(color: Colors.blue)),
                Text('Partner: $partnerCost KRW', style: const TextStyle(color: Colors.red)),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Message
        TextField(
          controller: _messageController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Message (Optional)',
            hintText: 'Let\'s meet for coffee!',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),

        // Gift Button (New)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              if (widget.onGift != null) {
                widget.onGift!();
              }
            },
            icon: const Icon(Icons.card_giftcard, color: Colors.white),
            label: const Text('커피 쏘기 (10,000 P) ☕', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber, // Gold color
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Send Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _handleSend,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Send Proposal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRatioButton(String label, double ratio) {
    final isSelected = _proposerRatio == ratio;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _proposerRatio = ratio;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        elevation: isSelected ? 2 : 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
