import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../routes/app_routes.dart';
import '../../services/customer_info_service.dart';

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  final _customerInfoService = CustomerInfoService();
  List<CustomerAddress> _savedAddresses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final addresses = await _customerInfoService.getAddresses();
      if (mounted) {
        setState(() {
          _savedAddresses = addresses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAddNewAddress() async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.mapPicker);
    if (result != null && mounted) {
      // Refresh addresses after adding new one
      _loadAddresses();
    }
  }

  Future<void> _handleUseCurrentLocation() async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.mapPicker);
    if (result != null && mounted) {
      // Refresh addresses after adding new one
      _loadAddresses();
    }
  }

  void _handleAddressSelected(CustomerAddress address) {
    Navigator.of(context).pop(address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      _TopBar(
                        title: 'Select Location',
                        onBack: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(height: 14),
                      const _SearchBar(),
                      const SizedBox(height: 12),
                      _QuickActionsSection(
                        onUseCurrentLocation: _handleUseCurrentLocation,
                        onAddNewAddress: _handleAddNewAddress,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Saved Addresses',
                        style:
                            AppTextStyles.header(color: const Color(0xFF1B1F2A)),
                      ),
                      const SizedBox(height: 10),
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_error != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Text(
                                  'Failed to load addresses',
                                  style: AppTextStyles.body(
                                      color: const Color(0xFF7B8296)),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _loadAddresses,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_savedAddresses.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              'No saved addresses yet',
                              style: AppTextStyles.body(
                                  color: const Color(0xFF7B8296)),
                            ),
                          ),
                        )
                      else
                        ..._savedAddresses.map((address) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _SavedAddressTile(
                                address: address,
                                onTap: () => _handleAddressSelected(address),
                                onEdit: () {
                                  // TODO: Implement edit functionality
                                },
                                onDelete: () async {
                                  // TODO: Implement delete functionality
                                  _loadAddresses();
                                },
                              ),
                            )),
                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _TopBar({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Color(0xFF1B1F2A),
                ),
              ),
            ),
          ),
          Text(
            title,
            style: AppTextStyles.header(color: const Color(0xFF1B1F2A)),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE9ECF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 20, color: Color(0xFF98A0B5)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search Address',
              style: AppTextStyles.body(color: const Color(0xFF98A0B5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onAddNewAddress;

  const _QuickActionsSection({
    required this.onUseCurrentLocation,
    required this.onAddNewAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Card(
          child: Column(
            children: [
              _QuickActionRow(
                icon: Icons.my_location_rounded,
                iconColor: const Color(0xFF2C3CA5),
                title: 'Use my Current Location',
                titleColor: const Color(0xFF2C3CA5),
                onTap: onUseCurrentLocation,
              ),
              const Divider(height: 1, color: Color(0xFFE9ECF3)),
              _QuickActionRow(
                icon: Icons.add,
                iconColor: const Color(0xFF2C3CA5),
                title: 'Add New Address',
                titleColor: const Color(0xFF2C3CA5),
                onTap: onAddNewAddress,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _Card(
          child: _QuickActionRow(
            icon: Icons.chat_bubble_rounded,
            iconColor: const Color(0xFF16A34A),
            title: 'Request Address from Friend',
            titleColor: const Color(0xFF1B1F2A),
            onTap: () {
              // TODO: Implement request address from friend
            },
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9ECF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color titleColor;
  final VoidCallback onTap;

  const _QuickActionRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.header(color: titleColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedAddressTile extends StatelessWidget {
  final CustomerAddress address;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SavedAddressTile({
    required this.address,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE9ECF3)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getAddressIcon(address.addressLabel),
                size: 20,
                color: const Color(0xFF1B1F2A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.addressLabel,
                        style: AppTextStyles.header(
                            color: const Color(0xFF1B1F2A)),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C3CA5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Default',
                            style: AppTextStyles.body(color: Colors.white)
                                .copyWith(fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address.fullAddress,
                    style: AppTextStyles.body(color: const Color(0xFF7B8296)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _AddressMenu(
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAddressIcon(String label) {
    final lowerLabel = label.toLowerCase();
    if (lowerLabel.contains('home') || lowerLabel.contains('house')) {
      return Icons.home_rounded;
    } else if (lowerLabel.contains('work') || lowerLabel.contains('office')) {
      return Icons.work_rounded;
    } else {
      return Icons.apartment_rounded;
    }
  }
}

enum _AddressMenuAction { edit, delete }

class _AddressMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressMenu({
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_AddressMenuAction>(
      padding: EdgeInsets.zero,
      onSelected: (v) {
        switch (v) {
          case _AddressMenuAction.edit:
            onEdit();
            break;
          case _AddressMenuAction.delete:
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _AddressMenuAction.edit,
          child: Text('Edit'),
        ),
        PopupMenuItem(
          value: _AddressMenuAction.delete,
          child: Text('Delete'),
        ),
      ],
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Icon(
          Icons.more_vert_rounded,
          size: 20,
          color: Color(0xFF7B8296),
        ),
      ),
    );
  }
}
