import 'package:equatable/equatable.dart';

/// Links configured in the single document of the `links` collection.
class AppLinks extends Equatable {
  const AppLinks({
    this.giveLink,
    this.privacyPolicyLink,
    this.termsOfUseLink,
    this.helpEmail,
    this.reportEmail,
  });

  final String? giveLink;
  final String? privacyPolicyLink;
  final String? termsOfUseLink;
  final String? helpEmail;
  final String? reportEmail;

  @override
  List<Object?> get props =>
      [giveLink, privacyPolicyLink, termsOfUseLink, helpEmail, reportEmail];
}
