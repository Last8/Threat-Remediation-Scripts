These fake McAfee pop-ups are abusive Web Push Notifications originating from a website the user visited, rather than an active malware infection on disk.

The remediation script below performs the necessary actions: it closes Edge, sets an enterprise policy key to block all web push notifications, and purges existing Edge notification permissions and Service Workers across all user profiles on the endpoint .

