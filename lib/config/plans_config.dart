class PlanInfo {
  /// Must match the plan names the consultation form and landing page use.
  final String name;
  final String priceKes;
  final String priceUsd;
  final String audience;
  final List<String> features;
  final bool recommended;

  const PlanInfo({
    required this.name,
    required this.priceKes,
    required this.priceUsd,
    required this.audience,
    required this.features,
    this.recommended = false,
  });
}

class PlansConfig {
  static const List<PlanInfo> plans = [
    PlanInfo(
      name: 'Entry',
      priceKes: 'KES 5,200',
      priceUsd: '\$40',
      audience: 'Small shops & boutiques',
      features: ['Basic Inventory', '5 Users', 'Email Support'],
    ),
    PlanInfo(
      name: 'Mid',
      priceKes: 'KES 13,000',
      priceUsd: '\$100',
      audience: 'Growing SMEs',
      features: [
        'Advanced Analytics',
        '20 Users',
        'Priority Support',
        'Stock Predictions',
      ],
      recommended: true,
    ),
    PlanInfo(
      name: 'High',
      priceKes: 'KES 45,500',
      priceUsd: '\$350',
      audience: 'Retail chains',
      features: [
        'Unlimited Users',
        'Dedicated Support',
        'Custom Integrations',
        'Multi-location',
      ],
    ),
  ];
}
