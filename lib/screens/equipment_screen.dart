import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../painters/paddle_preview_painter.dart';
import '../services/storage_service.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({Key? key}) : super(key: key);

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  List<PaddleData> _paddles = [];
  PaddleData? _equippedPaddle;
  int _userCoins = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final paddles = await StorageService.getPaddles();
    final equipped = await StorageService.getEquippedPaddle();
    final coins = await StorageService.getCoins();
    if (mounted) {
      setState(() {
        _paddles = paddles;
        _equippedPaddle = equipped;
        _userCoins = coins;
        _isLoading = false;
      });
    }
  }

  Future<void> _equipPaddle(PaddleData paddle) async {
    await StorageService.setEquippedPaddle(paddle);
    await _loadData();
  }

  Future<void> _unlockPaddle(PaddleData paddle) async {
    if (_userCoins >= paddle.price) {
      await StorageService.setCoins(_userCoins - paddle.price);
      await StorageService.unlockPaddle(paddle.id);
      await StorageService.setEquippedPaddle(paddle);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('UNLOCKED AND EQUIPPED ${paddle.name.toUpperCase()}!'),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NOT ENOUGH COINS!'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'BLACK MARKET GEAR',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1F232C),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amberAccent, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on,
                    color: Colors.amberAccent, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$_userCoins',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.amberAccent))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _paddles.length,
              itemBuilder: (context, index) {
                final paddle = _paddles[index];
                final isEquipped = _equippedPaddle?.id == paddle.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F232C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isEquipped
                          ? Colors.amberAccent
                          : (paddle.isUnlocked
                              ? Colors.white12
                              : Colors.white10),
                      width: isEquipped ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: paddle.rarity.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: paddle.rarity.color),
                            ),
                            child: PaddlePreviewWidget(
                              paddle: paddle,
                              width: 52,
                              height: 52,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  paddle.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  paddle.rarity.label,
                                  style: TextStyle(
                                    color: paddle.rarity.color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isEquipped)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amberAccent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'EQUIPPED',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildStatBar('POWER', paddle.power, Colors.redAccent),
                      const SizedBox(height: 8),
                      _buildStatBar(
                          'CONTROL', paddle.control, Colors.blueAccent),
                      const SizedBox(height: 8),
                      _buildStatBar('SPIN', paddle.spin, Colors.purpleAccent),
                      const SizedBox(height: 16),
                      if (!isEquipped)
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: paddle.isUnlocked
                                ? () => _equipPaddle(paddle)
                                : () => _unlockPaddle(paddle),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: paddle.isUnlocked
                                  ? Colors.white24
                                  : Colors.amberAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              paddle.isUnlocked
                                  ? 'EQUIP PADDLE'
                                  : 'UNLOCK FOR ${paddle.price} COINS',
                              style: TextStyle(
                                color: paddle.isUnlocked
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatBar(String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100.0,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 30,
          child: Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
