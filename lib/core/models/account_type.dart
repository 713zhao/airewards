/// Enum representing different account types in the family system
enum AccountType {
  /// Parent account with full management permissions
  parent('parent'),
  
  /// Child account with limited permissions
  child('child');

  const AccountType(this.value);
  
  /// String value for persistence and API communication
  final String value;
  
  /// Parse AccountType from string value
  static AccountType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'parent':
        return AccountType.parent;
      case 'child':
        return AccountType.child;
      default:
        return AccountType.child; // Default to child for safety
    }
  }
  
  /// Check if this account type has management permissions
  bool get hasManagementPermissions => this == AccountType.parent;
  
  /// Check if this is a parent account
  bool get isParent => this == AccountType.parent;
  
  /// Check if this is a child account
  bool get isChild => this == AccountType.child;
  
  /// Get display name for account type
  String get displayName {
    switch (this) {
      case AccountType.parent:
        return 'Parent';
      case AccountType.child:
        return 'Child';
    }
  }
  
  /// Get description for account type
  String get description {
    switch (this) {
      case AccountType.parent:
        return 'Full access to manage tasks, rewards, and view all family activity';
      case AccountType.child:
        return 'Can complete tasks and redeem rewards';
    }
  }
}