import React, { useEffect, useState } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  Alert,
  StyleSheet,
  ScrollView,
  Platform,
} from "react-native";
import { AppMetricaPush } from "../src";

/**
 * Краткий пример использования AppMetrica Push SDK
 */
export const BasicExample: React.FC = () => {
  const [isInitialized, setIsInitialized] = useState(false);
  const [sdkInfo, setSdkInfo] = useState<any>(null);
  const [logs, setLogs] = useState<string[]>([]);

  const addLog = (message: string) => {
    setLogs((prev) => [
      ...prev,
      `${new Date().toLocaleTimeString()}: ${message}`,
    ]);
  };

  useEffect(() => {
    addLog(`App started on ${Platform.OS}`);
    checkSDKStatus();
  }, []);

  const checkSDKStatus = async () => {
    try {
      const info = await AppMetricaPush.getSDKInfo();
      setSdkInfo(info);
      setIsInitialized(true);
      addLog("SDK is ready");
    } catch (error) {
      addLog(`SDK not ready: ${error}`);
    }
  };

  const handleInitialize = async () => {
    try {
      addLog("Initializing AppMetrica Push SDK...");
      const result = await AppMetricaPush.initialize({
        debugMode: __DEV__,
      });

      if (result.success) {
        addLog("✅ SDK initialized successfully");
        setIsInitialized(true);
        await checkSDKStatus();
      } else {
        addLog(`❌ Failed to initialize: ${result.error}`);
      }
    } catch (error) {
      addLog(`❌ Error: ${error}`);
    }
  };

  const handleTestNotification = async () => {
    try {
      addLog("Testing notification detection...");

      // Тестовое уведомление от AppMetrica
      const testNotification = {
        data: {
          ym_push_id: "test_123",
          ym_campaign_id: "campaign_456",
        },
      };

      const isFromAppMetrica =
        await AppMetricaPush.isNotificationFromAppMetrica(testNotification);

      addLog(
        `Notification from AppMetrica: ${isFromAppMetrica ? "✅ Yes" : "❌ No"}`
      );

      if (isFromAppMetrica) {
        const userData = await AppMetricaPush.getUserData(testNotification);
        addLog(`User data: ${JSON.stringify(userData)}`);
      }
    } catch (error) {
      addLog(`❌ Error testing notification: ${error}`);
    }
  };

  const handleGetSDKInfo = async () => {
    try {
      const info = await AppMetricaPush.getSDKInfo();
      setSdkInfo(info);
      addLog(`SDK Info: ${JSON.stringify(info, null, 2)}`);
    } catch (error) {
      addLog(`❌ Error getting SDK info: ${error}`);
    }
  };

  const clearLogs = () => setLogs([]);

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>AppMetrica Push SDK</Text>

      <View style={styles.statusCard}>
        <Text style={styles.statusText}>
          Platform: <Text style={styles.highlight}>{Platform.OS}</Text>
        </Text>
        <Text style={styles.statusText}>
          Status:{" "}
          <Text
            style={[
              styles.highlight,
              {
                color: isInitialized ? "#4CAF50" : "#F44336",
              },
            ]}
          >
            {isInitialized ? "Ready" : "Not initialized"}
          </Text>
        </Text>
        {sdkInfo && (
          <Text style={styles.statusText}>
            Version: <Text style={styles.highlight}>{sdkInfo.version}</Text>
          </Text>
        )}
      </View>

      <View style={styles.buttonContainer}>
        <TouchableOpacity
          style={[styles.button, styles.primaryButton]}
          onPress={handleInitialize}
        >
          <Text style={styles.buttonText}>Initialize SDK</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.button, styles.secondaryButton]}
          onPress={handleTestNotification}
        >
          <Text style={styles.buttonText}>Test Notification</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.button, styles.tertiaryButton]}
          onPress={handleGetSDKInfo}
        >
          <Text style={styles.buttonText}>Get SDK Info</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.button, styles.dangerButton]}
          onPress={clearLogs}
        >
          <Text style={styles.buttonText}>Clear Logs</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.logsContainer}>
        <Text style={styles.logsTitle}>Logs:</Text>
        {logs.map((log, index) => (
          <Text key={index} style={styles.logText}>
            {log}
          </Text>
        ))}
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: "#f5f5f5",
  },
  title: {
    fontSize: 24,
    fontWeight: "bold",
    textAlign: "center",
    marginBottom: 20,
    color: "#333",
  },
  statusCard: {
    backgroundColor: "#fff",
    padding: 15,
    borderRadius: 8,
    marginBottom: 20,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  statusText: {
    fontSize: 16,
    marginBottom: 8,
    color: "#666",
  },
  highlight: {
    fontWeight: "bold",
    color: "#2196F3",
  },
  buttonContainer: {
    gap: 12,
    marginBottom: 20,
  },
  button: {
    padding: 15,
    borderRadius: 8,
    alignItems: "center",
  },
  primaryButton: {
    backgroundColor: "#2196F3",
  },
  secondaryButton: {
    backgroundColor: "#4CAF50",
  },
  tertiaryButton: {
    backgroundColor: "#FF9800",
  },
  dangerButton: {
    backgroundColor: "#F44336",
  },
  buttonText: {
    color: "#fff",
    fontSize: 16,
    fontWeight: "600",
  },
  logsContainer: {
    backgroundColor: "#fff",
    padding: 15,
    borderRadius: 8,
    maxHeight: 300,
  },
  logsTitle: {
    fontSize: 16,
    fontWeight: "600",
    marginBottom: 10,
    color: "#333",
  },
  logText: {
    fontSize: 12,
    color: "#666",
    marginBottom: 4,
    fontFamily: "monospace",
  },
});
