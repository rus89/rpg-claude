// ABOUTME: Decodes a list of bytes from Windows-1250 encoding to a Dart String.
// ABOUTME: Dart has no built-in Windows-1250 codec; this provides one for Serbian CSV data.

/// Decodes [bytes] from Windows-1250 encoding into a Dart string.
///
/// Bytes 0x00–0x7F map to ASCII (same as Latin-1).
/// Bytes 0x80–0xFF are mapped to Unicode using the Windows-1250 code page table.
String windows1250Decode(List<int> bytes) {
  final buffer = StringBuffer();
  for (final b in bytes) {
    if (b < 0x80) {
      buffer.writeCharCode(b);
    } else {
      buffer.writeCharCode(_table[b - 0x80]);
    }
  }
  return buffer.toString();
}

/// Windows-1250 mapping for bytes 0x80–0xFF to Unicode code points.
/// Source: https://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP1250.TXT
const _table = <int>[
  // 0x80–0x8F
  0x20AC, // 80 €
  0xFFFD, // 81 undefined → replacement char
  0x201A, // 82 ‚
  0xFFFD, // 83 undefined
  0x201E, // 84 „
  0x2026, // 85 …
  0x2020, // 86 †
  0x2021, // 87 ‡
  0xFFFD, // 88 undefined
  0x2030, // 89 ‰
  0x0160, // 8A Š
  0x2039, // 8B ‹
  0x015A, // 8C Ś
  0x0164, // 8D Ť
  0x017D, // 8E Ž
  0x0179, // 8F Ź
  // 0x90–0x9F
  0xFFFD, // 90 undefined
  0x2018, // 91 '
  0x2019, // 92 '
  0x201C, // 93 "
  0x201D, // 94 "
  0x2022, // 95 •
  0x2013, // 96 –
  0x2014, // 97 —
  0xFFFD, // 98 undefined
  0x2122, // 99 ™
  0x0161, // 9A š
  0x203A, // 9B ›
  0x015B, // 9C ś
  0x0165, // 9D ť
  0x017E, // 9E ž
  0x017A, // 9F ź
  // 0xA0–0xAF
  0x00A0, // A0 non-breaking space
  0x02C7, // A1 ˇ
  0x02D8, // A2 ˘
  0x0141, // A3 Ł
  0x00A4, // A4 ¤
  0x0104, // A5 Ą
  0x00A6, // A6 ¦
  0x00A7, // A7 §
  0x00A8, // A8 ¨
  0x00A9, // A9 ©
  0x015E, // AA Ş
  0x00AB, // AB «
  0x00AC, // AC ¬
  0x00AD, // AD soft hyphen
  0x00AE, // AE ®
  0x017B, // AF Ż
  // 0xB0–0xBF
  0x00B0, // B0 °
  0x00B1, // B1 ±
  0x02DB, // B2 ˛
  0x0142, // B3 ł
  0x00B4, // B4 ´
  0x00B5, // B5 µ
  0x00B6, // B6 ¶
  0x00B7, // B7 ·
  0x00B8, // B8 ¸
  0x0105, // B9 ą
  0x015F, // BA ş
  0x00BB, // BB »
  0x013D, // BC Ľ
  0x02DD, // BD ˝
  0x013E, // BE ľ
  0x017C, // BF ż
  // 0xC0–0xCF
  0x0154, // C0 Ŕ
  0x00C1, // C1 Á
  0x00C2, // C2 Â
  0x0102, // C3 Ă
  0x00C4, // C4 Ä
  0x0139, // C5 Ĺ
  0x0106, // C6 Ć
  0x00C7, // C7 Ç
  0x010C, // C8 Č
  0x00C9, // C9 É
  0x0118, // CA Ę
  0x00CB, // CB Ë
  0x011A, // CC Ě
  0x00CD, // CD Í
  0x00CE, // CE Î
  0x010E, // CF Ď
  // 0xD0–0xDF
  0x0110, // D0 Đ
  0x0143, // D1 Ń
  0x0147, // D2 Ň
  0x00D3, // D3 Ó
  0x00D4, // D4 Ô
  0x0150, // D5 Ő
  0x00D6, // D6 Ö
  0x00D7, // D7 ×
  0x0158, // D8 Ř
  0x016E, // D9 Ů
  0x00DA, // DA Ú
  0x0170, // DB Ű
  0x00DC, // DC Ü
  0x00DD, // DD Ý
  0x0162, // DE Ţ
  0x00DF, // DF ß
  // 0xE0–0xEF
  0x0155, // E0 ŕ
  0x00E1, // E1 á
  0x00E2, // E2 â
  0x0103, // E3 ă
  0x00E4, // E4 ä
  0x013A, // E5 ĺ
  0x0107, // E6 ć
  0x00E7, // E7 ç
  0x010D, // E8 č
  0x00E9, // E9 é
  0x0119, // EA ę
  0x00EB, // EB ë
  0x011B, // EC ě
  0x00ED, // ED í
  0x00EE, // EE î
  0x010F, // EF ď
  // 0xF0–0xFF
  0x0111, // F0 đ
  0x0144, // F1 ń
  0x0148, // F2 ň
  0x00F3, // F3 ó
  0x00F4, // F4 ô
  0x0151, // F5 ő
  0x00F6, // F6 ö
  0x00F7, // F7 ÷
  0x0159, // F8 ř
  0x016F, // F9 ů
  0x00FA, // FA ú
  0x0171, // FB ű
  0x00FC, // FC ü
  0x00FD, // FD ý
  0x0163, // FE ţ
  0x02D9, // FF ˙
];
