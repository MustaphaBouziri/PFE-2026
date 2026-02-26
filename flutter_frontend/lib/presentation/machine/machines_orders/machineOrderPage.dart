import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/machines/providers/machineOrders_provider.dart';

class Machineorderpage extends StatefulWidget {
  final String machineNo;

  const Machineorderpage({super.key, required this.machineNo});

  @override
  State<Machineorderpage> createState() => _MachineorderpageState();
}

class _MachineorderpageState extends State<Machineorderpage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MachineordersProvider>().getMachineOrders(widget.machineNo);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MachineordersProvider>();
    final machineOrdersList = provider.machineOrders;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Machine Orders - ${widget.machineNo}'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
          ? Center(child: Text(provider.errorMessage!))
          : machineOrdersList.isEmpty
          ? const Center(child: Text('No Orders Found'))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Order Cards ──────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: machineOrdersList.length,
              itemBuilder: (context, index) {
                final order = machineOrdersList[index];
                final style = _badgeStyle(order.status);

                return Opacity(
                  opacity: order.status == 'Firm Planned' ? 1.0 : 0.75,
                  child: _OrderCard(order: order, badgeStyle: style),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge style resolver ──────────────────────────────────────────────────────

class _BadgeStyle {
  final Color bg;
  final Color border;
  final Color text;
  final String label;

  const _BadgeStyle({
    required this.bg,
    required this.border,
    required this.text,
    required this.label,
  });
}

_BadgeStyle _badgeStyle(String status) {
  switch (status) {
    case 'Firm Planned':
      return const _BadgeStyle(
        bg: Color(0xFFF3F0FF),
        border: Color(0xFFDDD6FE),
        text: Color(0xFF5B21B6),
        label: 'FIRM PLANNED',
      );
    case 'Planned':
      return const _BadgeStyle(
        bg: Color(0xFFF3F4F6),
        border: Color(0xFFE5E7EB),
        text: Color(0xFF6B7280),
        label: 'PLANNED',
      );
    case 'Released':
    default:
      return const _BadgeStyle(
        bg: Color(0xFFECFDF5),
        border: Color(0xFFA7F3D0),
        text: Color(0xFF065F46),
        label: 'RELEASED',
      );
  }
}

// ── Order Card ────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final dynamic order;
  final _BadgeStyle badgeStyle;

  const _OrderCard({required this.order, required this.badgeStyle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 520;
              return isWide
                  ? _WideLayout(order: order, badgeStyle: badgeStyle)
                  : _NarrowLayout(order: order, badgeStyle: badgeStyle);
            },
          ),
        ),
      ),
    );
  }
}

// ── Wide Layout ───────────────────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  final dynamic order;
  final _BadgeStyle badgeStyle;

  const _WideLayout({required this.order, required this.badgeStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BadgeAndId(order: order, badgeStyle: badgeStyle),
              const SizedBox(height: 12),
              _InfoGrid(order: order),
            ],
          ),
        ),
        const SizedBox(width: 16),
        const _ActionButtons(),
      ],
    );
  }
}

// ── Narrow Layout ─────────────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  final dynamic order;
  final _BadgeStyle badgeStyle;

  const _NarrowLayout({required this.order, required this.badgeStyle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BadgeAndId(order: order, badgeStyle: badgeStyle),
        const SizedBox(height: 12),
        _InfoGrid(order: order),
        const SizedBox(height: 14),
        const _ActionButtons(fullWidth: true),
      ],
    );
  }
}

// ── Badge + Order ID ──────────────────────────────────────────────────────────

class _BadgeAndId extends StatelessWidget {
  final dynamic order;
  final _BadgeStyle badgeStyle;

  const _BadgeAndId({required this.order, required this.badgeStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: badgeStyle.bg,
            border: Border.all(color: badgeStyle.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badgeStyle.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: badgeStyle.text,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'ORD-${order.orderNo}',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

// ── Info Grid ─────────────────────────────────────────────────────────────────

class _InfoGrid extends StatelessWidget {
  final dynamic order;

  const _InfoGrid({required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _InfoCell(label: 'Product', value: order.itemDescription ?? '—'),
        const SizedBox(width: 16),
        _InfoCell(label: 'Planned Qty', value: '${order.orderQuantity} Units'),
        const SizedBox(width: 16),
        _InfoCell(
          label: 'Start',
          value: order.plannedStart != null ? '${order.plannedStart}' : '—',
        ),
        const SizedBox(width: 16),
        _InfoCell(
          label: 'End',
          value: order.plannedEnd != null ? '${order.plannedEnd}' : '—',
        ),
      ],
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;

  const _InfoCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Action Buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final bool fullWidth;

  const _ActionButtons({this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    final closeBtn = OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF334155),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: const Text(
        'Close',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );

    final startBtn = ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
      label: const Text(
        'Start Order',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F172A),
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );

    if (fullWidth) {
      return Row(
        children: [
          Expanded(child: closeBtn),
          const SizedBox(width: 10),
          Expanded(child: startBtn),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [closeBtn, const SizedBox(width: 10), startBtn],
    );
  }
}
