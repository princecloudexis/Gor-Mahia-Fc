import 'package:gormahiafc/models/policy_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final privacyPolicyProvider = FutureProvider.autoDispose<List<PolicyModel>>((
  ref,
) async {
  // Simulate a quick network load
  await Future.delayed(const Duration(milliseconds: 300));
  return [
    PolicyModel(
      id: 1,
      title: 'Information We Collect',
      description: 'When you use GormahiaFc to purchase Gor Mahia FC match tickets or merchandise, we may collect your name, phone number, email address, and payment information to process your transactions securely.',
    ),
    PolicyModel(
      id: 2,
      title: 'How We Use Your Data',
      description: 'Your data is strictly used for processing your ticket orders, verifying your identity at stadium gates, and sending you critical updates regarding Gor Mahia FC matches, schedule changes, and club news.',
    ),
    PolicyModel(
      id: 3,
      title: 'Data Sharing & Security',
      description: 'We do not sell your personal data. We only share necessary details with secure third-party payment gateways to complete your purchases. All data is encrypted and securely stored.',
    ),
    PolicyModel(
      id: 4,
      title: 'Contact Us',
      description: 'If you have any questions regarding your privacy or data, please contact the official Gor Mahia FC support team at info@gormahia.com or through our official social media channels.',
    ),
  ];
});

final termsOfServiceProvider = FutureProvider.autoDispose<List<PolicyModel>>((
  ref,
) async {
  // Simulate a quick network load
  await Future.delayed(const Duration(milliseconds: 300));
  return [
    PolicyModel(
      id: 1,
      title: 'Acceptance of Terms',
      description: 'By using GormahiaFc, you agree to abide by these terms. This app is the official ticketing platform for Gor Mahia FC. Any unauthorized use or ticket scalping is strictly prohibited.',
    ),
    PolicyModel(
      id: 2,
      title: 'Ticket Purchases & Refunds',
      description: 'All ticket sales are final. Refunds are only issued if a Gor Mahia FC match is officially cancelled and not rescheduled. Tickets are non-transferable unless explicitly stated.',
    ),
    PolicyModel(
      id: 3,
      title: 'Stadium Rules',
      description: 'Purchasing a ticket grants you entry to the stadium subject to Gor Mahia FC and stadium management rules. We reserve the right to revoke tickets for abusive behavior or safety violations.',
    ),
    PolicyModel(
      id: 4,
      title: 'Updates to Terms',
      description: 'Gor Mahia FC reserves the right to update these terms at any time. Continued use of the GormahiaFc app constitutes your acceptance of any new terms.',
    ),
  ];
});
