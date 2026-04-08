# Privacy Policy - IMU (Itinerary Manager Uniformed)

**Last Updated:** April 7, 2026
**App Version:** 1.3.2
**Developer:** ODVI
**Contact:** privacy@odvi.com
**Website:** [Coming Soon]

---

## 1. Introduction

Welcome to IMU (Itinerary Manager Uniformed). This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application. Please read this privacy policy carefully. If you do not agree with the terms of this privacy policy, please do not use the application.

---

## 2. Information We Collect

### 2.1 Personal Information
We collect the following personal information:

- **Name and Contact Details**: First name, last name, middle name, email address, phone numbers
- **Authentication Credentials**: Email address, password (encrypted), 6-digit PIN
- **Device Information**: Device model, operating system version, unique device identifier
- **Location Information**: GPS coordinates, current address, municipality, province
- **Biometric Data**: Fingerprint or Face ID data (stored securely on device only)
- **Photos and Audio**: Client visit photos and voice recordings (with consent)

### 2.2 Automatically Collected Information
- **Usage Data**: App features used, time spent in app, crash reports, performance data
- **Log Data**: IP address, device event information, logs, and other diagnostic data
- **Location Data**: Real-time GPS location during touchpoint creation

### 2.3 Client Data (Business Purpose)
The app is designed for field agents managing client relationships. Client information collected includes:
- Personal details (name, birth date, PAN, addresses)
- Contact information (phone numbers, email)
- Employment and agency information
- Touchpoint history and visit records

---

## 3. How We Use Your Information

We use the collected information for the following purposes:

### 3.1 Core App Functionality
- **Account Management**: To create and authenticate your user account
- **Client Management**: To display and manage client information
- **Touchpoint Tracking**: To record client visits and calls
- **Itinerary Management**: To schedule and manage daily visits
- **Location Verification**: To verify agent location during touchpoint creation
- **Offline Sync**: To store data locally when offline and sync when online

### 3.2 Security and Authentication
- **Biometric Authentication**: To enable fingerprint/Face ID login
- **Session Management**: To manage user sessions and automatic timeout
- **Access Control**: To enforce role-based permissions (Caravan, Tele, Manager)

### 3.3 Communication and Support
- **Notifications**: To send sync status updates and task reminders
- **Customer Support**: To respond to your inquiries and provide technical support

### 3.4 Analytics and Improvement
- **Performance Monitoring**: To analyze app performance and fix bugs
- **Usage Analytics**: To understand how the app is used and improve features
- **Error Reporting**: To automatically log and report app crashes

---

## 4. Data Storage and Security

### 4.1 Local Storage
- **On-Device Storage**: Client data is stored locally using Hive (encrypted local database)
- **Authentication Tokens**: JWT tokens stored in flutter_secure_storage (encrypted keychain)
- **Biometric Data**: Stored securely on device using local_auth (never transmitted)
- **Photos and Audio**: Stored locally until synced to backend server

### 4.2 Cloud Storage
- **Backend Server**: Data synced to PostgreSQL database (encrypted at rest and in transit)
- **PowerSync Service**: Offline-first synchronization service (encrypted connection)
- **AWS S3**: For photo and audio file storage (encrypted buckets)

### 4.3 Security Measures
We implement industry-standard security measures:
- **Encryption**: All data encrypted during transmission (TLS/SSL)
- **Authentication**: JWT-based authentication with 15-minute session timeout
- **Access Control**: Role-based permissions (Admin, Area Manager, Caravan, Tele)
- **Secure Storage**: Sensitive data stored in encrypted keychain/keystore
- **Regular Audits**: Periodic security reviews and vulnerability assessments

---

## 5. Location Data

### 5.1 GPS Location Collection
We collect GPS location data for the following purposes:
- **Touchpoint Verification**: To verify agent location during client visits
- **Address Validation**: To validate and autocomplete client addresses
- **Route Optimization**: To suggest optimal routes for client visits (future feature)

### 5.2 Location Usage
- **Foreground Only**: Location is only collected when app is in use (during touchpoint creation)
- **No Background Tracking**: We do not track location when app is in background
- **Precise Location**: We require accurate GPS for touchpoint verification
- **User Consent**: Location permission is requested at first use and can be revoked

---

## 6. Camera and Microphone

### 6.1 Camera Usage
We access your device camera for:
- **Client Photos**: To capture photos during client visits (with consent)
- **Documentation**: To document touchpoint locations and client interactions
- **User Control**: Camera access is only initiated when you tap the photo button

### 6.2 Microphone Usage
We access your device microphone for:
- **Voice Notes**: To record voice memos during touchpoint creation
- **Audio Documentation**: To capture detailed notes during client visits
- **User Control**: Microphone access is only initiated when you tap the record button

---

## 7. Data Sharing and Disclosure

We do not sell, trade, or rent your personal information. We may share your information only in the following circumstances:

### 7.1 Service Providers
- **Backend Services**: With our backend API and database hosting providers
- **PowerSync**: With PowerSync service for data synchronization
- **Analytics**: With analytics providers for app performance monitoring
- **Cloud Storage**: With AWS for photo and audio file storage

### 7.2 Business Transfers
- **Mergers and Acquisitions**: In connection with any merger, sale of company assets
- **Business Successors**: Information transferred to successors in interest

### 7.3 Legal Requirements
- **Compliance**: To comply with legal obligations and court orders
- **Protection**: To protect our rights, privacy, safety, and property
- **Prevention**: To prevent fraud or illegal activities

### 7.4 Client Data Access
- **Role-Based Access**: Field agents only see clients assigned to their territory
- **Manager Oversight**: Area managers can view clients within their jurisdiction
- **Admin Access**: Administrators have full system access for management purposes

---

## 8. Data Retention

### 8.1 Retention Period
- **Active Data**: Client data retained while client relationship is active
- **Touchpoint History**: Touchpoint records retained for 7 years (business requirement)
- **Inactive Clients**: Data archived after 2 years of inactivity
- **User Accounts**: Account data retained for 30 days after account deletion

### 8.2 Local Data
- **Offline Data**: Local data automatically synced when online
- **Cache Clearing**: Local cache cleared after 7 days of inactivity
- **User Control**: Users can clear app data through device settings

---

## 9. Your Rights and Choices

### 9.1 Data Access and Portability
- **View Data**: You can view all data stored about you through the app
- **Export Data**: You can request a copy of your personal data
- **Delete Account**: You can request account deletion (data retained for legal requirements)

### 9.2 Permission Control
- **Location**: You can revoke location permission at any time
- **Camera/Microphone**: You can revoke camera/microphone permission at any time
- **Notifications**: You can disable notifications through app settings

### 9.3 Authentication Settings
- **Biometric Login**: You can enable/disable biometric authentication
- **PIN Management**: You can change your 6-digit PIN anytime
- **Session Timeout**: Automatic logout after 15 minutes of inactivity

---

## 10. Children's Privacy

This application is not intended for children under the age of 13. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately.

---

## 11. International Data Transfers

Your information may be transferred to and processed in countries other than your country of residence. We ensure that your data is protected in accordance with this Privacy Policy and applicable laws.

**Data Storage Locations:**
- **Primary Server**: Philippines (DigitalOcean, Singapore region)
- **Backup Servers**: Secure cloud storage (AWS Asia Pacific)
- **Sync Service**: PowerSync (global edge network)

---

## 12. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. We will notify you of any changes by:
- Posting the new Privacy Policy in the app
- Sending an email notification (if provided)
- Updating the "Last Updated" date

**Your continued use of the app after modifications constitutes your acceptance of the updated Privacy Policy.**

---

## 13. Contact Information

If you have any questions, concerns, or requests regarding this Privacy Policy or our data practices, please contact us:

**Developer:** ODVI
**Email:** privacy@odvi.com
**Website:** [Coming Soon]
**Address:** Cebu City, Philippines

---

## 14. Legal Basis for Processing (GDPR Compliance)

For users in the European Economic Area (EEA), we process your personal data based on:

- **Contract Necessity**: To provide the app services under our user agreement
- **Legitimate Interests**: For analytics, security, and app improvement
- **Consent**: For optional features like biometric authentication and location services
- **Legal Obligation**: To comply with financial and business record-keeping requirements

---

## 15. Data Subject Rights (GDPR)

Under GDPR, you have the right to:
- **Access**: Request a copy of your personal data
- **Rectification**: Request correction of inaccurate data
- **Erasure**: Request deletion of your personal data
- **Restrict**: Request restriction of data processing
- **Portability**: Request data transfer to another service
- **Object**: Object to data processing based on legitimate interests
- **Withdraw Consent**: Withdraw consent at any time

To exercise these rights, contact us at privacy@odvi.com

---

**This Privacy Policy is effective as of April 7, 2026**

---

*For questions or concerns about privacy practices, please contact our Data Protection Officer at privacy@odvi.com*
