import 'package:flutter/material.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF282828),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Terms of Use',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    'Last updated: March 14, 2024',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    'Please read these Terms of Use ("Terms", "Terms of Use") carefully before using the Just Learn mobile application (the "Service") operated by Just Learn ("us", "we", or "our").',
                  ),
                  const SizedBox(height: 32),
                  _buildTitle('Subscriptions'),
                  _buildSection(
                    'Some parts of the Service are billed on a subscription basis ("Subscription(s)"). You will be billed in advance on a recurring and periodic basis ("Billing Cycle"). Billing cycles are set on a monthly or six-monthly basis, depending on the type of subscription plan you select.\n\nAt the end of each Billing Cycle, your Subscription will automatically renew under the exact same conditions unless you cancel it or we cancel it. You may cancel your Subscription renewal through your iTunes/App Store account settings.',
                  ),
                  const SizedBox(height: 32),
                  _buildTitle('Free Trial'),
                  _buildSection(
                    'We may, at our sole discretion, offer a Subscription with a free trial for a limited period of time ("Free Trial"). You may be required to enter your billing information in order to sign up for the Free Trial.\n\nIf you do enter your billing information when signing up for the Free Trial, you will not be charged by us until the Free Trial has expired. On the last day of the Free Trial period, unless you cancelled your Subscription, you will be automatically charged the applicable Subscription fees for the type of Subscription you have selected.',
                  ),
                  const SizedBox(height: 32),
                  _buildTitle('Content'),
                  _buildSection(
                    'Our Service allows you to post, link, store, share and otherwise make available certain information, text, graphics, videos, or other material ("Content"). You are responsible for the Content that you post to the Service, including its legality, reliability, and appropriateness.',
                  ),
                  const SizedBox(height: 32),
                  _buildTitle('Contact Us'),
                  _buildSection(
                    'If you have any questions about these Terms, please contact us:',
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      // Add email handling
                    },
                    child: const Text(
                      'hello@justlearnapp.com',
                      style: TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.yellowAccent,
          fontSize: 20,
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSection(String text, {TextStyle? style}) {
    return Text(
      text,
      style: style ?? TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 16,
        height: 1.5,
      ),
    );
  }
} 