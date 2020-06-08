/// The subscription frequency options
enum BillingFrequency { yearly, monthly }

/// The subscription team option
enum TeamsOption { basic, premium }

extension PlanExtension on TeamsOption {
  String get name {
    switch (this) {
      case TeamsOption.premium:
        return 'premium';
      case TeamsOption.basic:
      default:
        return 'normal';
    }
  }
}

extension FrequencyExtension on BillingFrequency {
  String get name {
    switch (this) {
      case BillingFrequency.yearly:
        return 'yearly';
      case BillingFrequency.monthly:
      default:
        return 'monthly';
    }
  }

  static BillingFrequency fromName(String cycle) {
    switch (cycle) {
      case 'monthly':
        return BillingFrequency.monthly;
      case 'yearly':
        return BillingFrequency.yearly;
      default:
        throw ArgumentError('Invalid billing frequency: $cycle');
    }
  }
}

class RiveTeamBilling {
  TeamsOption plan;

  BillingFrequency frequency;

  RiveTeamBilling({this.plan, this.frequency});

  factory RiveTeamBilling.fromData(Map<String, dynamic> data) {
    return RiveTeamBilling(
      plan: data.getPlan(),
      frequency: data.getFrequency(),
    );
  }

  @override
  String toString() {
    return '${plan.toString()} & ${frequency.toString()}';
  }
}

extension DeserializeHelperHelper on Map<String, dynamic> {
  TeamsOption getPlan() {
    dynamic value = this['plan'];
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'normal':
          return TeamsOption.basic;
        case 'premium':
          return TeamsOption.premium;
        default:
          return null;
      }
    }
    return null;
  }

  BillingFrequency getFrequency() {
    dynamic value = this['cycle'];
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'monthly':
          return BillingFrequency.monthly;
        case 'yearly':
          return BillingFrequency.yearly;
        default:
          return null;
      }
    }
    return null;
  }
}
