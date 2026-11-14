import 'package:flutter/material.dart';
import '../../logic/player_economy_service.dart';

class PauseModal extends StatelessWidget {
  final int currentLevel;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onBackToMap;

  const PauseModal({
    super.key,
    required this.currentLevel,
    required this.onResume,
    required this.onRestart,
    required this.onBackToMap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF3B2314),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF9E633A), width: 3.0),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 8)),
            ],
          ),
          child: SingleChildScrollView(
            child: ListenableBuilder(
              listenable: PlayerEconomyService.instance,
              builder: (context, _) {
                final economy = PlayerEconomyService.instance;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('⏸️', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              currentLevel == 0 ? 'TẠM DỪNG (FTUE)' : 'TẠM DỪNG - MÀN $currentLevel',
                              style: const TextStyle(
                                color: Color(0xFFFFD84D),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Các nút bật/tắt BGM, SFX, Haptics
                    _buildToggleRow(
                      icon: Icons.music_note_rounded,
                      title: 'Nhạc nền (BGM)',
                      value: economy.bgmEnabled,
                      onChanged: (v) => economy.setBgmEnabled(v),
                    ),
                    const SizedBox(height: 8),
                    _buildToggleRow(
                      icon: Icons.volume_up_rounded,
                      title: 'Âm thanh hiệu ứng (SFX)',
                      value: economy.sfxEnabled,
                      onChanged: (v) => economy.setSfxEnabled(v),
                    ),
                    const SizedBox(height: 8),
                    _buildToggleRow(
                      icon: Icons.vibration_rounded,
                      title: 'Rung xúc giác (Haptics)',
                      value: economy.hapticsEnabled,
                      onChanged: (v) => economy.setHapticsEnabled(v),
                    ),
                    const SizedBox(height: 20),

                    // Nút Tiếp tục
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4BC226),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text(
                          'TIẾP TỤC CHƠI',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                        onPressed: onResume,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Nút Chơi lại & Về Bản đồ
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                side: const BorderSide(color: Color(0xFFFFD84D), width: 1.5),
                                foregroundColor: const Color(0xFFFFD84D),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('CHƠI LẠI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              onPressed: onRestart,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                side: const BorderSide(color: Color(0xFFFF9E99), width: 1.5),
                                foregroundColor: const Color(0xFFFF9E99),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              icon: const Icon(Icons.map_rounded, size: 16),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('VỀ BẢN ĐỒ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              onPressed: onBackToMap,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4A2E1B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6D4226)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD84D), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF81E659),
            activeTrackColor: const Color(0xFF2D8512),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

