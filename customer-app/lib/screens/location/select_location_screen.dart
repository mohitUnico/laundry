import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';

class SelectLocationScreen extends StatelessWidget {
  const SelectLocationScreen({super.key});

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
                      const _QuickActionsSection(),
                      const SizedBox(height: 16),
                      Text(
                        'Saved Addresses',
                        style:
                            AppTextStyles.header(color: const Color(0xFF1B1F2A)),
                      ),
                      const SizedBox(height: 10),
                      const _SavedAddressTile(
                        label: 'Work',
                        addressLine1: 'Flat No. 58, Wing C, Sunrise Apartments',
                        addressLine2:
                            'Carter Road, Bandra West Bandra, Mumbai...',
                      ),
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
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _Card(
          child: Column(
            children: [
              _QuickActionRow(
                icon: Icons.my_location_rounded,
                iconColor: Color(0xFF2C3CA5),
                title: 'Use my Current Location',
                titleColor: Color(0xFF2C3CA5),
              ),
              Divider(height: 1, color: Color(0xFFE9ECF3)),
              _QuickActionRow(
                icon: Icons.add,
                iconColor: Color(0xFF2C3CA5),
                title: 'Add New Address',
                titleColor: Color(0xFF2C3CA5),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        _Card(
          child: _QuickActionRow(
            icon: Icons.chat_bubble_rounded,
            iconColor: Color(0xFF16A34A),
            title: 'Request Address from Friend',
            titleColor: Color(0xFF1B1F2A),
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

  const _QuickActionRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
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
  final String label;
  final String addressLine1;
  final String addressLine2;

  const _SavedAddressTile({
    required this.label,
    required this.addressLine1,
    required this.addressLine2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: const Icon(
              Icons.apartment_rounded,
              size: 20,
              color: Color(0xFF1B1F2A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.header(color: const Color(0xFF1B1F2A)),
                ),
                const SizedBox(height: 2),
                Text(
                  addressLine1,
                  style: AppTextStyles.body(color: const Color(0xFF7B8296)),
                ),
                const SizedBox(height: 2),
                Text(
                  addressLine2,
                  style: AppTextStyles.body(color: const Color(0xFF7B8296)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _AddressMenu(
            onEdit: () {},
            onDelete: () {},
          ),
        ],
      ),
    );
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


