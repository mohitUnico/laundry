import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';

/// A reusable phone field widget with country code picker.
/// Handles phone numbers in the format: "+91 9876543210"
class PhoneFieldWithCountryPicker extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final String? errorText;
  final ValueChanged<Country>? onCountryChanged;
  final Country? initialCountry;

  const PhoneFieldWithCountryPicker({
    super.key,
    required this.controller,
    required this.hintText,
    this.enabled = true,
    this.errorText,
    this.onCountryChanged,
    this.initialCountry,
  });

  @override
  State<PhoneFieldWithCountryPicker> createState() => _PhoneFieldWithCountryPickerState();

  /// Parse phone number from storage format (e.g., "+91 9876543210" or "9876543210")
  /// Returns [Country, phoneNumberWithoutCountryCode]
  static List<dynamic> parsePhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return [Country.parse('IN'), '']; // Default to India
    }

    final trimmed = phoneNumber.trim();
    
    // Check if phone starts with + (has country code)
    if (trimmed.startsWith('+')) {
      // Try to parse country code (usually 1-3 digits after +)
      final parts = trimmed.split(' ');
      if (parts.length >= 2) {
        final countryCodeStr = parts[0]; // e.g., "+91"
        final phoneWithoutCode = parts.sublist(1).join(' '); // Rest of the number
        
        try {
          // Try to find country by dial code
          final country = _findCountryByDialCode(countryCodeStr);
          return [country, phoneWithoutCode];
        } catch (_) {
          // If parsing fails, default to India
          return [Country.parse('IN'), trimmed.replaceFirst('+', '').trim()];
        }
      } else {
        // Just "+91" format without space - extract country code
        final match = RegExp(r'^\+(\d{1,3})(.*)$').firstMatch(trimmed);
        if (match != null) {
          final codeStr = '+${match.group(1)}';
          final phoneStr = match.group(2) ?? '';
          try {
            final country = _findCountryByDialCode(codeStr);
            return [country, phoneStr.trim()];
          } catch (_) {
            // Default to India
            return [Country.parse('IN'), trimmed.replaceFirst(codeStr, '').trim()];
          }
        }
      }
    }
    
    // No country code found, assume India (+91)
    return [Country.parse('IN'), trimmed];
  }

  /// Find country by dial code (e.g., "+91")
  static Country _findCountryByDialCode(String dialCode) {
    // Remove + from dial code
    final code = dialCode.replaceFirst('+', '').trim();
    
    // Common country code to ISO code mapping
    final codeToIsoMap = {
      '91': 'IN',  // India
      '1': 'US',   // United States
      '44': 'GB',  // United Kingdom
      '86': 'CN',  // China
      '81': 'JP',  // Japan
      '49': 'DE',  // Germany
      '33': 'FR',  // France
      '39': 'IT',  // Italy
      '34': 'ES',  // Spain
      '7': 'RU',   // Russia
      '61': 'AU',  // Australia
      '55': 'BR',  // Brazil
      '52': 'MX',  // Mexico
      '82': 'KR',  // South Korea
      '971': 'AE', // UAE
      '65': 'SG',  // Singapore
      '60': 'MY',  // Malaysia
      '66': 'TH',  // Thailand
      '84': 'VN',  // Vietnam
      '62': 'ID',  // Indonesia
      '92': 'PK',  // Pakistan
      '880': 'BD', // Bangladesh
      '94': 'LK',  // Sri Lanka
    };
    
    // Try to find by code
    final isoCode = codeToIsoMap[code];
    if (isoCode != null) {
      try {
        return Country.parse(isoCode);
      } catch (_) {
        // If parse fails, default to India
      }
    }
    
    // Default to India if not found
    return Country.parse('IN');
  }

  /// Format phone number for storage: "+91 9876543210"
  static String formatPhoneForStorage(Country country, String phoneNumber) {
    final cleaned = phoneNumber.trim().replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return '';
    return '+${country.phoneCode} $cleaned';
  }
}

class _PhoneFieldWithCountryPickerState extends State<PhoneFieldWithCountryPicker> {
  late Country _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry ?? Country.parse('IN');
  }

  void _onCountryChanged(Country country) {
    setState(() {
      _selectedCountry = country;
    });
    widget.onCountryChanged?.call(country);
  }

  void _showCountryPicker() {
    if (!widget.enabled) return;

    showCountryPicker(
      context: context,
      showPhoneCode: true,
      favorite: const ['IN'], // India as favorite
      countryListTheme: CountryListThemeData(
        flagSize: 25,
        backgroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
        searchTextStyle: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
        inputDecoration: InputDecoration(
          hintText: 'Search country',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      onSelect: _onCountryChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: hasError ? Colors.red : const Color(0xFFE5E7EB),
              width: 1.6,
            ),
          ),
          child: Row(
            children: [
              // Country Code Button - Shows flag + dial code (e.g., "🇮🇳 +91")
              GestureDetector(
                onTap: _showCountryPicker,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 75),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Country flag emoji (smaller)
                      Flexible(
                        child: Text(
                          _selectedCountry.flagEmoji,
                          style: const TextStyle(fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Dial code (e.g., "+91")
                      Flexible(
                        flex: 0,
                        child: Text(
                          '+${_selectedCountry.phoneCode}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      // Dropdown icon (smaller)
                      Icon(
                        Icons.arrow_drop_down,
                        size: 16,
                        color: widget.enabled ? Colors.black : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              // Divider
              Container(
                width: 1,
                height: 30,
                color: const Color(0xFFE5E7EB),
                margin: const EdgeInsets.symmetric(vertical: 8),
              ),
              // Phone Number Input - Takes remaining space
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  keyboardType: TextInputType.phone,
                  enabled: widget.enabled,
                  scrollPadding: EdgeInsets.zero,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: const TextStyle(
                      color: Color(0xFFB8BDCF),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
