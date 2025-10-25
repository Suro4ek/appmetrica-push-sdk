import React, { useEffect, useState } from "react";
import {
  View,
  Text,
  Button,
  StyleSheet,
  Alert,
  Platform,
  ScrollView,
} from "react-native";
import {
  initializeAppMetricaPush,
  isNotificationFromAppMetrica,
  getPushSDKInfo,
  isSDKInitialized,
  useAppMetricaPush,
} from "../src";

const IOSExample: React.FC = () => {
  const { sdkInfo, isInitialized, isLoading } = useAppMetricaPush();
  const [testResults, setTestResults] = useState<string[]>([]);

  const addTestResult = (result: string) => {
    setTestResults((prev) => [
      ...prev,
      `${new Date().toLocaleTimeString()}: ${result}`,
    ]);
  };

  const testInitialization = async () => {
    try {
      addTestResult("Testing initialization...");
      const result = await initializeAppMetricaPush({
        debugMode: true,
      });
      addTestResult(`Initialization result: ${result}`);
    } catch (error) {
      addTestResult(`Initialization error: ${error}`);
    }
  };

  const testSDKInfo = async () => {
    try {
      addTestResult("Testing SDK info...");
      const info = await getPushSDKInfo();
      addTestResult(`SDK Info: ${JSON.stringify(info)}`);
    } catch (error) {
      addTestResult(`SDK Info error: ${error}`);
    }
  };

  const testNotificationCheck = async () => {
    try {
      addTestResult("Testing notification check...");

      // Тестовое уведомление от AppMetrica
      const appMetricaNotification = {
        data: {
          ym_push_id: "test_push_id",
          ym_campaign_id: "test_campaign",
          ym_message_id: "test_message",
        },
      };

      // Обычное уведомление
      const regularNotification = {
        data: {
          title: "Regular notification",
          body: "This is not from AppMetrica",
        },
      };

      const isAppMetrica1 = await isNotificationFromAppMetrica(
        appMetricaNotification
      );
      const isAppMetrica2 = await isNotificationFromAppMetrica(
        regularNotification
      );

      addTestResult(`AppMetrica notification detected: ${isAppMetrica1}`);
      addTestResult(`Regular notification detected: ${isAppMetrica2}`);
    } catch (error) {
      addTestResult(`Notification check error: ${error}`);
    }
  };

  const testSDKStatus = () => {
    const initialized = isSDKInitialized();
    addTestResult(`SDK initialized: ${initialized}`);
  };

  const clearResults = () => {
    setTestResults([]);
  };

  useEffect(() => {
    addTestResult(`Platform: ${Platform.OS}`);
    addTestResult("iOS Example loaded");
  }, []);

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>AppMetrica Push SDK - iOS Test</Text>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>SDK Status</Text>
        <Text>Initialized: {isInitialized ? "Yes" : "No"}</Text>
        <Text>Loading: {isLoading ? "Yes" : "No"}</Text>
        {sdkInfo && <Text>SDK Info: {JSON.stringify(sdkInfo, null, 2)}</Text>}
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Tests</Text>
        <Button title="Test Initialization" onPress={testInitialization} />
        <Button title="Test SDK Info" onPress={testSDKInfo} />
        <Button
          title="Test Notification Check"
          onPress={testNotificationCheck}
        />
        <Button title="Test SDK Status" onPress={testSDKStatus} />
        <Button title="Clear Results" onPress={clearResults} />
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Test Results</Text>
        {testResults.map((result, index) => (
          <Text key={index} style={styles.resultText}>
            {result}
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
    marginBottom: 20,
    textAlign: "center",
  },
  section: {
    marginBottom: 20,
    padding: 15,
    backgroundColor: "white",
    borderRadius: 8,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: "bold",
    marginBottom: 10,
    color: "#333",
  },
  resultText: {
    fontSize: 12,
    color: "#666",
    marginBottom: 5,
    fontFamily: Platform.OS === "ios" ? "Courier" : "monospace",
  },
});

export default IOSExample;
