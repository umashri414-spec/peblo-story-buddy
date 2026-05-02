import React, { useState } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Alert,
  ScrollView,
  StatusBar,
  Platform,
} from "react-native";
import * as DocumentPicker from "expo-document-picker";
import * as FileSystem from "expo-file-system";
import * as Sharing from "expo-sharing";
const API_BASE_URL = "https://pdf-converter-backend-rokj.onrender.com";

const CONVERSIONS = [
  {
    id: "pdf-to-word",
    title: "PDF to Word",
    subtitle: "Convert PDF → .docx file",
    icon: "📝",
    endpoint: "/convert/pdf-to-word",
    outputExt: ".docx",
    color: "#2B5CE6",
  },
  {
    id: "pdf-to-image",
    title: "PDF to Image",
    subtitle: "Convert PDF → JPG images (ZIP)",
    icon: "🖼️",
    endpoint: "/convert/pdf-to-image",
    outputExt: ".zip",
    color: "#E63B2B",
  },
  {
    id: "pdf-to-excel",
    title: "PDF to Excel",
    subtitle: "Extract tables → .xlsx file",
    icon: "📊",
    endpoint: "/convert/pdf-to-excel",
    outputExt: ".xlsx",
    color: "#1D7A3A",
  },
];

export default function App() {
  const [selectedFile, setSelectedFile] = useState(null);
  const [loading, setLoading] = useState(false);
  const [activeConversion, setActiveConversion] = useState(null);
  const [convertedFile, setConvertedFile] = useState(null);

  const pickFile = async () => {
    try {
      const result = await DocumentPicker.getDocumentAsync({
        type: "application/pdf",
        copyToCacheDirectory: true,
      });

      if (!result.canceled && result.assets?.length > 0) {
        setSelectedFile(result.assets[0]);
        setConvertedFile(null);
      }
    } catch (err) {
      Alert.alert("Error", "Failed to pick file");
    }
  };

  const convertFile = async (conversion) => {
    if (!selectedFile) {
      Alert.alert("No File", "Please select a PDF file first!");
      return;
    }

    setLoading(true);
    setActiveConversion(conversion.id);
    setConvertedFile(null);

    try {
      const formData = new FormData();
      formData.append("file", {
        uri: selectedFile.uri,
        name: selectedFile.name,
        type: "application/pdf",
      });

      const response = await fetch(`${API_BASE_URL}${conversion.endpoint}`, {
        method: "POST",
        body: formData,
        headers: {
          "Content-Type": "multipart/form-data",
        },
      });

      if (!response.ok) {
        const errData = await response.json();
        throw new Error(errData.detail || "Conversion failed");
      }

      // Save file to device
      const outputFileName =
        selectedFile.name.replace(".pdf", "") + conversion.outputExt;
      const outputPath = FileSystem.documentDirectory + outputFileName;

      const blob = await response.blob();
      const reader = new FileReader();

      reader.onloadend = async () => {
        const base64 = reader.result.split(",")[1];
        await FileSystem.writeAsStringAsync(outputPath, base64, {
          encoding: FileSystem.EncodingType.Base64,
        });

        setConvertedFile({ path: outputPath, name: outputFileName });
        setLoading(false);
        setActiveConversion(null);
        Alert.alert("✅ Success!", `${outputFileName} converted successfully!`);
      };

      reader.readAsDataURL(blob);
    } catch (error) {
      setLoading(false);
      setActiveConversion(null);
      Alert.alert("❌ Error", error.message || "Something went wrong");
    }
  };

  const shareFile = async () => {
    if (!convertedFile) return;
    try {
      if (await Sharing.isAvailableAsync()) {
        await Sharing.shareAsync(convertedFile.path);
      } else {
        Alert.alert("Info", "Sharing not available on this device");
      }
    } catch (err) {
      Alert.alert("Error", "Could not share file");
    }
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#1a1a2e" />

      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>📄 PDF Converter</Text>
        <Text style={styles.headerSub}>Free & Unlimited Conversions</Text>
      </View>

      <ScrollView contentContainerStyle={styles.scroll}>
        {/* File Picker */}
        <TouchableOpacity style={styles.pickBtn} onPress={pickFile}>
          <Text style={styles.pickIcon}>📂</Text>
          <Text style={styles.pickTitle}>
            {selectedFile ? selectedFile.name : "Select PDF File"}
          </Text>
          <Text style={styles.pickSub}>
            {selectedFile
              ? `${(selectedFile.size / 1024).toFixed(1)} KB — Tap to change`
              : "Tap to browse your files"}
          </Text>
        </TouchableOpacity>

        {/* Conversion Cards */}
        <Text style={styles.sectionTitle}>Choose Conversion</Text>

        {CONVERSIONS.map((conv) => (
          <TouchableOpacity
            key={conv.id}
            style={[styles.convCard, { borderLeftColor: conv.color }]}
            onPress={() => convertFile(conv)}
            disabled={loading}
          >
            <View style={styles.convLeft}>
              <Text style={styles.convIcon}>{conv.icon}</Text>
              <View>
                <Text style={styles.convTitle}>{conv.title}</Text>
                <Text style={styles.convSub}>{conv.subtitle}</Text>
              </View>
            </View>
            {loading && activeConversion === conv.id ? (
              <ActivityIndicator color={conv.color} />
            ) : (
              <Text style={[styles.convertBtn, { color: conv.color }]}>
                Convert →
              </Text>
            )}
          </TouchableOpacity>
        ))}

        {/* Download Section */}
        {convertedFile && (
          <View style={styles.downloadCard}>
            <Text style={styles.downloadTitle}>✅ Ready to Download!</Text>
            <Text style={styles.downloadName}>{convertedFile.name}</Text>
            <TouchableOpacity style={styles.shareBtn} onPress={shareFile}>
              <Text style={styles.shareBtnText}>📤 Share / Save File</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* Footer */}
        <Text style={styles.footer}>Powered by PDF Converter API 🚀</Text>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#f0f2f5",
  },
  header: {
    backgroundColor: "#1a1a2e",
    paddingTop: Platform.OS === "android" ? 40 : 60,
    paddingBottom: 20,
    paddingHorizontal: 20,
  },
  headerTitle: {
    color: "#fff",
    fontSize: 24,
    fontWeight: "bold",
  },
  headerSub: {
    color: "#aaa",
    fontSize: 13,
    marginTop: 2,
  },
  scroll: {
    padding: 16,
    paddingBottom: 40,
  },
  pickBtn: {
    backgroundColor: "#fff",
    borderRadius: 16,
    padding: 20,
    alignItems: "center",
    marginBottom: 20,
    borderWidth: 2,
    borderColor: "#2B5CE6",
    borderStyle: "dashed",
  },
  pickIcon: {
    fontSize: 36,
    marginBottom: 8,
  },
  pickTitle: {
    fontSize: 15,
    fontWeight: "600",
    color: "#1a1a2e",
    textAlign: "center",
  },
  pickSub: {
    fontSize: 12,
    color: "#888",
    marginTop: 4,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: "700",
    color: "#1a1a2e",
    marginBottom: 12,
  },
  convCard: {
    backgroundColor: "#fff",
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    borderLeftWidth: 4,
    elevation: 2,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 3,
  },
  convLeft: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    flex: 1,
  },
  convIcon: {
    fontSize: 28,
    marginRight: 10,
  },
  convTitle: {
    fontSize: 15,
    fontWeight: "600",
    color: "#1a1a2e",
  },
  convSub: {
    fontSize: 12,
    color: "#888",
    marginTop: 2,
  },
  convertBtn: {
    fontSize: 14,
    fontWeight: "700",
  },
  downloadCard: {
    backgroundColor: "#e8f5e9",
    borderRadius: 12,
    padding: 16,
    marginTop: 8,
    alignItems: "center",
    borderWidth: 1,
    borderColor: "#4CAF50",
  },
  downloadTitle: {
    fontSize: 16,
    fontWeight: "700",
    color: "#2e7d32",
  },
  downloadName: {
    fontSize: 13,
    color: "#555",
    marginTop: 4,
    marginBottom: 12,
  },
  shareBtn: {
    backgroundColor: "#2e7d32",
    paddingHorizontal: 24,
    paddingVertical: 10,
    borderRadius: 8,
  },
  shareBtnText: {
    color: "#fff",
    fontWeight: "600",
    fontSize: 14,
  },
  footer: {
    textAlign: "center",
    color: "#aaa",
    fontSize: 12,
    marginTop: 24,
  },
});
