#include "flutter_window.h"

#include <winspool.h>
#include <windows.h>

#include <optional>
#include <string>
#include <vector>

#include "flutter/generated_plugin_registrant.h"

namespace {

std::string WideToUtf8(const std::wstring& value) {
  if (value.empty()) {
    return std::string();
  }
  const int size_needed = WideCharToMultiByte(
      CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()), nullptr, 0,
      nullptr, nullptr);
  std::string result(size_needed, '\0');
  WideCharToMultiByte(CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()),
                      result.data(), size_needed, nullptr, nullptr);
  return result;
}

std::wstring Utf8ToWide(const std::string& value) {
  if (value.empty()) {
    return std::wstring();
  }
  const int size_needed = MultiByteToWideChar(
      CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()), nullptr, 0);
  std::wstring result(size_needed, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()),
                      result.data(), size_needed);
  return result;
}

std::string WideToAnsi(const std::wstring& value) {
  if (value.empty()) {
    return std::string();
  }
  const int size_needed = WideCharToMultiByte(
      CP_ACP, 0, value.c_str(), static_cast<int>(value.size()), nullptr, 0,
      nullptr, nullptr);
  std::string result(size_needed, '\0');
  WideCharToMultiByte(CP_ACP, 0, value.c_str(), static_cast<int>(value.size()),
                      result.data(), size_needed, nullptr, nullptr);
  return result;
}

bool GetDefaultPrinterName(std::wstring* printer_name) {
  DWORD size = 0;
  GetDefaultPrinterW(nullptr, &size);
  if (size == 0) {
    return false;
  }
  std::vector<wchar_t> buffer(size, L'\0');
  if (!GetDefaultPrinterW(buffer.data(), &size)) {
    return false;
  }
  *printer_name = std::wstring(buffer.data());
  return !printer_name->empty();
}

bool PrintRawBytes(const std::wstring& printer_name,
                   const std::vector<uint8_t>& bytes,
                   std::string* error_message);

bool PrintRawText(const std::wstring& printer_name, const std::string& text,
                  std::string* error_message) {
  std::vector<uint8_t> bytes(text.begin(), text.end());
  bytes.push_back('\r');
  bytes.push_back('\n');
  bytes.push_back('\r');
  bytes.push_back('\n');
  // ESC/POS partial cut command (GS V 1).
  bytes.push_back(0x1D);
  bytes.push_back(0x56);
  bytes.push_back(0x01);
  return PrintRawBytes(printer_name, bytes, error_message);
}

bool PrintRawBytes(const std::wstring& printer_name,
                   const std::vector<uint8_t>& bytes,
                   std::string* error_message) {
  HANDLE printer_handle = nullptr;
  if (!OpenPrinterW(const_cast<LPWSTR>(printer_name.c_str()), &printer_handle,
                    nullptr)) {
    if (error_message != nullptr) {
      *error_message = "Unable to open printer.";
    }
    return false;
  }

  DOC_INFO_1W doc_info{};
  doc_info.pDocName = const_cast<LPWSTR>(L"Rons Pizza Kitchen Ticket");
  doc_info.pDatatype = const_cast<LPWSTR>(L"RAW");

  const DWORD job_id = StartDocPrinterW(printer_handle, 1, (LPBYTE)&doc_info);
  if (job_id == 0) {
    if (error_message != nullptr) {
      *error_message = "Unable to start print job.";
    }
    ClosePrinter(printer_handle);
    return false;
  }

  if (!StartPagePrinter(printer_handle)) {
    if (error_message != nullptr) {
      *error_message = "Unable to start printer page.";
    }
    EndDocPrinter(printer_handle);
    ClosePrinter(printer_handle);
    return false;
  }

  DWORD written = 0;
  const BOOL write_ok =
      WritePrinter(printer_handle, (LPVOID)bytes.data(),
                   static_cast<DWORD>(bytes.size()), &written);

  EndPagePrinter(printer_handle);
  EndDocPrinter(printer_handle);
  ClosePrinter(printer_handle);

  if (!write_ok || written == 0) {
    if (error_message != nullptr) {
      *error_message = "Unable to write ticket bytes to printer.";
    }
    return false;
  }
  return true;
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  printer_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "rons_pizza/printing",
          &flutter::StandardMethodCodec::GetInstance());
  printer_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        const std::string method = call.method_name();
        const bool is_text = (method == "printKitchenTicket" ||
                              method == "printCustomerReceipt");
        const bool is_bytes = (method == "printKitchenTicketBytes" ||
                               method == "printCustomerReceiptBytes");
        if (!is_text && !is_bytes) {
          result->NotImplemented();
          return;
        }

        std::wstring printer_name;
        if (!GetDefaultPrinterName(&printer_name)) {
          result->Error("PRINTER_NOT_FOUND",
                        "No default printer is configured in Windows.");
          return;
        }

        std::string error_message;

        if (is_text) {
          const auto* args =
              std::get_if<flutter::EncodableMap>(call.arguments());
          if (args == nullptr) {
            result->Error("INVALID_ARGUMENTS",
                          "Expected map arguments with ticket text.");
            return;
          }

          const auto text_it = args->find(flutter::EncodableValue("text"));
          if (text_it == args->end()) {
            result->Error("INVALID_ARGUMENTS", "Missing 'text' argument.");
            return;
          }

          const auto* text = std::get_if<std::string>(&text_it->second);
          if (text == nullptr || text->empty()) {
            result->Error("INVALID_ARGUMENTS", "Ticket text is empty.");
            return;
          }

          const std::wstring text_wide = Utf8ToWide(*text);
          const std::string printable_text = WideToAnsi(text_wide);
          if (!PrintRawText(printer_name, printable_text, &error_message)) {
            const std::string printer_utf8 = WideToUtf8(printer_name);
            result->Error("PRINT_FAILED",
                          "Failed printing on '" + printer_utf8 +
                              "': " + error_message);
            return;
          }
        } else {
          const auto* args =
              std::get_if<flutter::EncodableMap>(call.arguments());
          if (args == nullptr) {
            result->Error("INVALID_ARGUMENTS",
                          "Expected map arguments with ticket bytes.");
            return;
          }

          const auto bytes_it = args->find(flutter::EncodableValue("bytes"));
          if (bytes_it == args->end()) {
            result->Error("INVALID_ARGUMENTS", "Missing 'bytes' argument.");
            return;
          }

          const auto* bytes =
              std::get_if<std::vector<uint8_t>>(&bytes_it->second);
          if (bytes == nullptr || bytes->empty()) {
            result->Error("INVALID_ARGUMENTS", "Ticket bytes are empty.");
            return;
          }

          if (!PrintRawBytes(printer_name, *bytes, &error_message)) {
            const std::string printer_utf8 = WideToUtf8(printer_name);
            result->Error("PRINT_FAILED",
                          "Failed printing on '" + printer_utf8 +
                              "': " + error_message);
            return;
          }
        }

        result->Success(flutter::EncodableValue(true));
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (printer_channel_) {
    printer_channel_ = nullptr;
  }
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
