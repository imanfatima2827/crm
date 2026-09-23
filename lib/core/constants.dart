/// Fill these in with your Supabase project values.
/// Supabase Dashboard -> Project Settings -> API
class SupabaseConfig {
  static const String url = 'Project_URL';

  /// The publishable (anon) key from Project Settings -> API.
  /// Supabase renamed "anon key" to "publishable key" in newer projects;
  /// either the legacy anon key or the new publishable key works here.
  static const String publishableKey =
      'sb_publishable_key';
}

/// Table / view names, kept in one place so a schema rename only
/// needs to be updated here.
class Tables {
  static const roles = 'roles';
  static const leadSources = 'lead_sources';
  static const opportunityStages = 'opportunity_stages';
  static const profiles = 'profiles';
  static const products = 'products';
  static const leads = 'leads';
  static const customers = 'customers';
  static const opportunities = 'opportunities';
  static const opportunityProducts = 'opportunity_products';
  static const activities = 'activities';
  static const notifications = 'notifications';
  static const appSettings = 'app_settings';
  static const auditLogs = 'audit_logs';

  // Views
  static const vDashboardKpis = 'v_dashboard_kpis';
  static const vLeadsByStatus = 'v_leads_by_status';
  static const vDealsByStage = 'v_deals_by_stage';
  static const vMonthlySales = 'v_monthly_sales';
  static const vLeadSourcePerformance = 'v_lead_source_performance';
  static const vSalespersonPerformance = 'v_salesperson_performance';
  static const vWonLostOpportunities = 'v_won_lost_opportunities';
  static const vLeadConversionReport = 'v_lead_conversion_report';
  static const vCustomerActivityReport = 'v_customer_activity_report';
  static const vUpcomingActivities = 'v_upcoming_activities';
  static const vOverdueActivities = 'v_overdue_activities';
  static const vOpportunityValueBreakdown = 'v_opportunity_value_breakdown';
}

/// Enum string values, matching the Postgres enum types exactly.
class LeadStatus {
  static const values = [
    'new',
    'contacted',
    'interested',
    'qualified',
    'converted',
    'lost',
  ];
}

class CustomerType {
  static const values = ['individual', 'business', 'key_account'];
}

class CustomerStatus {
  static const values = ['active', 'inactive'];
}

class ProductType {
  static const values = ['product', 'service'];
}

class ActivityType {
  static const values = ['call', 'meeting', 'email', 'follow_up', 'note'];
}

class ActivityStatus {
  static const values = ['pending', 'completed', 'cancelled'];
}

class Priority {
  static const values = ['low', 'normal', 'high'];
}

class RoleSlug {
  static const admin = 'admin';
  static const salesManager = 'sales_manager';
  static const salesRep = 'sales_rep';
}

/// Currency codes offered on the App Settings screen, so admins pick from
/// a list instead of typing a raw currency code.
class CommonCurrencies {
  const CommonCurrencies._();
  static const List<MapEntry<String, String>> values = [
    MapEntry('USD', 'US Dollar'),
    MapEntry('EUR', 'Euro'),
    MapEntry('GBP', 'British Pound'),
    MapEntry('PKR', 'Pakistani Rupee'),
    MapEntry('INR', 'Indian Rupee'),
    MapEntry('AED', 'UAE Dirham'),
    MapEntry('SAR', 'Saudi Riyal'),
    MapEntry('CAD', 'Canadian Dollar'),
    MapEntry('AUD', 'Australian Dollar'),
    MapEntry('JPY', 'Japanese Yen'),
    MapEntry('CNY', 'Chinese Yuan'),
    MapEntry('CHF', 'Swiss Franc'),
    MapEntry('SGD', 'Singapore Dollar'),
    MapEntry('ZAR', 'South African Rand'),
    MapEntry('NGN', 'Nigerian Naira'),
    MapEntry('BDT', 'Bangladeshi Taka'),
    MapEntry('TRY', 'Turkish Lira'),
    MapEntry('MXN', 'Mexican Peso'),
    MapEntry('BRL', 'Brazilian Real'),
    MapEntry('SEK', 'Swedish Krona'),
  ];
}

/// Countries offered as the "default country" setting. Kept to a
/// practical common list rather than every ISO country.
class CommonCountries {
  const CommonCountries._();
  static const List<String> values = [
    'Pakistan',
    'United States',
    'United Kingdom',
    'United Arab Emirates',
    'Saudi Arabia',
    'India',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'China',
    'Japan',
    'Singapore',
    'South Africa',
    'Nigeria',
    'Bangladesh',
    'Turkey',
    'Mexico',
    'Brazil',
    'Sweden',
  ];
}