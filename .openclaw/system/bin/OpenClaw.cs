using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;
using System.Net.Sockets;

class OpenClaw {
    static void Main() {
        string baseDir = AppDomain.CurrentDomain.BaseDirectory;
        string scriptPath = Path.Combine(baseDir, ".openclaw", "OpenClaw_GUI.ps1");

        if (!File.Exists(scriptPath)) {
            MessageBox.Show(
                "CRITICAL: GUI script not found.\nExpected: " + scriptPath,
                "OpenClaw V3.0", MessageBoxButtons.OK, MessageBoxIcon.Error
            );
            return;
        }

        if (!IsOllamaRunning(2000)) {
            var result = MessageBox.Show(
                "Ollama is not running on port 11434.\n\n" +
                "OpenClaw V3.0 needs Ollama for AI inference.\n" +
                "Start Ollama first, or launch without AI?\n\n" +
                "Launch anyway?",
                "OpenClaw V3.0 — Brain Check",
                MessageBoxButtons.YesNo, MessageBoxIcon.Warning
            );
            if (result == DialogResult.No) return;
        }

        ProcessStartInfo psi = new ProcessStartInfo();
        psi.FileName = "powershell.exe";
        psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + scriptPath + "\"";
        psi.WindowStyle = ProcessWindowStyle.Hidden;
        psi.UseShellExecute = false;
        psi.CreateNoWindow = true;

        try {
            Process.Start(psi);
        } catch (Exception ex) {
            MessageBox.Show("Launch failed:\n" + ex.Message, "OpenClaw V3.0");
        }
    }

    static bool IsOllamaRunning(int timeoutMs) {
        try {
            using (TcpClient client = new TcpClient()) {
                var result = client.BeginConnect("127.0.0.1", 11434, null, null);
                bool success = result.AsyncWaitHandle.WaitOne(timeoutMs);
                if (success) { client.EndConnect(result); return true; }
                return false;
            }
        } catch { return false; }
    }
}
