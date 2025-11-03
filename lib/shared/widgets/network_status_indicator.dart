import 'package:flutter/material.dart';

import '../../core/locator/service_locator.dart';
import '../../core/network/network_info.dart';

/// Widget to display network connectivity status
class NetworkStatusIndicator extends StatelessWidget {
  const NetworkStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final networkInfo = ServiceLocator.networkInfo;

    return StreamBuilder<bool>(
      stream: networkInfo.connectivityStream,
      initialData: false,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isConnected ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConnected ? Icons.wifi : Icons.wifi_off,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                isConnected ? 'Online' : 'Offline',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Detailed network information widget
class NetworkInfoWidget extends StatefulWidget {
  const NetworkInfoWidget({super.key});

  @override
  State<NetworkInfoWidget> createState() => _NetworkInfoWidgetState();
}

class _NetworkInfoWidgetState extends State<NetworkInfoWidget> {
  final networkInfo = ServiceLocator.networkInfo;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Network Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Connection Status
            StreamBuilder<bool>(
              stream: networkInfo.connectivityStream,
              builder: (context, snapshot) {
                final isConnected = snapshot.data ?? false;
                return _buildInfoRow(
                  'Status',
                  isConnected ? 'Connected' : 'Disconnected',
                  isConnected ? Colors.green : Colors.red,
                );
              },
            ),
            
            // Connection Type
            FutureBuilder<ConnectionType>(
              future: networkInfo.connectionType,
              builder: (context, snapshot) {
                final connectionType = snapshot.data ?? ConnectionType.none;
                return _buildInfoRow(
                  'Type',
                  connectionType.name.toUpperCase(),
                  _getConnectionTypeColor(connectionType),
                );
              },
            ),
            
            // Mobile Connection
            FutureBuilder<bool>(
              future: networkInfo.isMobileConnection,
              builder: (context, snapshot) {
                final isMobile = snapshot.data ?? false;
                return _buildInfoRow(
                  'Mobile Data',
                  isMobile ? 'Yes' : 'No',
                  isMobile ? Colors.orange : Colors.grey,
                );
              },
            ),
            
            // WiFi Connection
            FutureBuilder<bool>(
              future: networkInfo.isWiFiConnection,
              builder: (context, snapshot) {
                final isWiFi = snapshot.data ?? false;
                return _buildInfoRow(
                  'WiFi',
                  isWiFi ? 'Yes' : 'No',
                  isWiFi ? Colors.blue : Colors.grey,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getConnectionTypeColor(ConnectionType type) {
    switch (type) {
      case ConnectionType.wifi:
        return Colors.blue;
      case ConnectionType.mobile:
        return Colors.orange;
      case ConnectionType.ethernet:
        return Colors.green;
      case ConnectionType.none:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}