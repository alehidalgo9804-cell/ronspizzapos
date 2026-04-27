import { useState } from "react";
import { ArrowLeft, Delete, CreditCard, DollarSign, Gift, Printer } from "lucide-react";

interface PaymentScreenProps {
  ticketNumber: string;
  tableNumber: string;
  orderTotal: number;
  onCancel: () => void;
  onComplete: () => void;
}

export function PaymentScreen({
  ticketNumber,
  tableNumber,
  orderTotal,
  onCancel,
  onComplete,
}: PaymentScreenProps) {
  const [receivedAmount, setReceivedAmount] = useState("");
  const [tipAmount, setTipAmount] = useState(0);
  const [selectedPaymentMethod, setSelectedPaymentMethod] = useState<"cash" | "card" | "gift" | null>(null);
  const [printTicket, setPrintTicket] = useState(true);

  const handleNumberClick = (value: string) => {
    if (value === "." && receivedAmount.includes(".")) return;
    setReceivedAmount(prev => prev + value);
  };

  const handleBackspace = () => {
    setReceivedAmount(prev => prev.slice(0, -1));
  };

  const handleQuickAmount = (amount: number) => {
    setReceivedAmount(amount.toString());
  };

  const totalWithTip = orderTotal + tipAmount;
  const receivedValue = parseFloat(receivedAmount) || 0;
  const changeAmount = receivedValue - totalWithTip;

  const handlePayment = () => {
    if (!selectedPaymentMethod) {
      alert("Please select a payment method");
      return;
    }

    if (selectedPaymentMethod === "cash" && receivedValue < totalWithTip) {
      alert("Received amount is less than total");
      return;
    }

    alert(
      `Payment completed!\n` +
      `Method: ${selectedPaymentMethod.toUpperCase()}\n` +
      `Total: $${totalWithTip.toFixed(2)}\n` +
      `Received: $${receivedValue.toFixed(2)}\n` +
      (selectedPaymentMethod === "cash" && changeAmount > 0 ? `Change: $${changeAmount.toFixed(2)}\n` : "") +
      (printTicket ? "Ticket will be printed" : "")
    );
    onComplete();
  };

  const handleCloseWithoutPayment = () => {
    if (confirm("Are you sure you want to close without payment?")) {
      onCancel();
    }
  };

  return (
    <div className="flex flex-col h-screen bg-gray-100">
      {/* HEADER */}
      <div className="bg-white border-b shadow-sm">
        <div className="flex items-center justify-between px-6 py-4">
          <button
            onClick={onCancel}
            className="flex items-center gap-2 text-gray-700 hover:text-gray-900 px-3 py-2 rounded-lg hover:bg-gray-100"
          >
            <ArrowLeft className="w-5 h-5" />
            <span className="font-medium">Cancel</span>
          </button>

          <div className="text-center">
            <div className="text-sm text-gray-500">Ticket #{ticketNumber}</div>
            <div className="text-lg font-semibold text-gray-900">Payment - Table {tableNumber}</div>
          </div>

          <div className="w-24"></div>
        </div>
      </div>

      {/* MAIN CONTENT */}
      <div className="flex flex-1 overflow-hidden">
        {/* LEFT SIDE - Numeric Keypad */}
        <div className="flex-1 flex flex-col p-8 bg-gray-50">
          <div className="max-w-md mx-auto w-full">
            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Amount Received
              </label>
              <div className="bg-white border-2 border-gray-300 rounded-lg px-6 py-4 text-right text-4xl font-bold text-gray-900 min-h-[80px] flex items-center justify-end">
                {receivedAmount ? `$${receivedAmount}` : "$0.00"}
              </div>
            </div>

            {/* Quick Amount Buttons */}
            <div className="grid grid-cols-2 gap-3 mb-4">
              <button
                onClick={() => handleQuickAmount(100)}
                className="bg-blue-600 hover:bg-blue-700 text-white rounded-lg py-3 text-xl font-semibold transition-colors"
              >
                $100
              </button>
              <button
                onClick={() => handleQuickAmount(150)}
                className="bg-blue-600 hover:bg-blue-700 text-white rounded-lg py-3 text-xl font-semibold transition-colors"
              >
                $150
              </button>
            </div>

            {/* Numeric Keypad */}
            <div className="grid grid-cols-3 gap-3">
              {["7", "8", "9", "4", "5", "6", "1", "2", "3", ".", "0"].map((num) => (
                <button
                  key={num}
                  onClick={() => handleNumberClick(num)}
                  className="bg-white hover:bg-gray-100 border-2 border-gray-300 rounded-lg py-6 text-2xl font-semibold text-gray-900 transition-colors"
                >
                  {num}
                </button>
              ))}
              <button
                onClick={handleBackspace}
                className="bg-red-500 hover:bg-red-600 text-white rounded-lg py-6 flex items-center justify-center transition-colors"
              >
                <Delete className="w-6 h-6" />
              </button>
            </div>

            {/* Change Display */}
            {selectedPaymentMethod === "cash" && receivedValue > 0 && (
              <div className="mt-6 bg-white border-2 border-gray-300 rounded-lg p-4">
                <div className="flex justify-between items-center text-lg">
                  <span className="font-medium text-gray-700">Change:</span>
                  <span className={`font-bold text-2xl ${changeAmount >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                    ${Math.abs(changeAmount).toFixed(2)}
                  </span>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* RIGHT SIDE - Payment Summary */}
        <div className="w-[450px] bg-white border-l flex flex-col">
          <div className="p-6 border-b">
            <h2 className="font-semibold text-xl text-gray-900">Payment Summary</h2>
          </div>

          <div className="flex-1 overflow-y-auto p-6 space-y-6">
            {/* Order Total */}
            <div className="bg-gray-50 rounded-lg p-4">
              <div className="flex justify-between items-center mb-2">
                <span className="text-gray-600">Order Total:</span>
                <span className="text-2xl font-bold text-gray-900">
                  ${orderTotal.toFixed(2)}
                </span>
              </div>
            </div>

            {/* Tip Field */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Tip Amount
              </label>
              <div className="flex gap-2">
                <input
                  type="number"
                  value={tipAmount}
                  onChange={(e) => setTipAmount(parseFloat(e.target.value) || 0)}
                  className="flex-1 border-2 border-gray-300 rounded-lg px-4 py-3 text-lg font-semibold"
                  placeholder="0.00"
                  step="0.01"
                  min="0"
                />
              </div>
              <div className="flex gap-2 mt-2">
                {[10, 15, 20].map((percent) => (
                  <button
                    key={percent}
                    onClick={() => setTipAmount((orderTotal * percent) / 100)}
                    className="flex-1 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-lg py-2 text-sm font-medium transition-colors"
                  >
                    {percent}%
                  </button>
                ))}
              </div>
            </div>

            {/* Total with Tip */}
            <div className="bg-blue-50 border-2 border-blue-200 rounded-lg p-4">
              <div className="flex justify-between items-center">
                <span className="text-lg font-medium text-gray-700">Total Amount:</span>
                <span className="text-3xl font-bold text-blue-600">
                  ${totalWithTip.toFixed(2)}
                </span>
              </div>
            </div>

            {/* Payment Methods */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-3">
                Payment Method
              </label>
              <div className="space-y-2">
                <button
                  onClick={() => setSelectedPaymentMethod("cash")}
                  className={`w-full flex items-center gap-3 px-4 py-4 rounded-lg border-2 transition-all ${
                    selectedPaymentMethod === "cash"
                      ? "border-green-600 bg-green-50 text-green-900"
                      : "border-gray-300 bg-white hover:bg-gray-50 text-gray-700"
                  }`}
                >
                  <DollarSign className="w-6 h-6" />
                  <span className="font-semibold text-lg">Cash</span>
                </button>
                <button
                  onClick={() => setSelectedPaymentMethod("card")}
                  className={`w-full flex items-center gap-3 px-4 py-4 rounded-lg border-2 transition-all ${
                    selectedPaymentMethod === "card"
                      ? "border-blue-600 bg-blue-50 text-blue-900"
                      : "border-gray-300 bg-white hover:bg-gray-50 text-gray-700"
                  }`}
                >
                  <CreditCard className="w-6 h-6" />
                  <span className="font-semibold text-lg">Credit Card</span>
                </button>
                <button
                  onClick={() => setSelectedPaymentMethod("gift")}
                  className={`w-full flex items-center gap-3 px-4 py-4 rounded-lg border-2 transition-all ${
                    selectedPaymentMethod === "gift"
                      ? "border-purple-600 bg-purple-50 text-purple-900"
                      : "border-gray-300 bg-white hover:bg-gray-50 text-gray-700"
                  }`}
                >
                  <Gift className="w-6 h-6" />
                  <span className="font-semibold text-lg">Gift Card</span>
                </button>
              </div>
            </div>

            {/* Print Ticket Toggle */}
            <div className="flex items-center justify-between bg-gray-50 rounded-lg p-4">
              <div className="flex items-center gap-2">
                <Printer className="w-5 h-5 text-gray-600" />
                <span className="font-medium text-gray-700">Print Ticket</span>
              </div>
              <button
                onClick={() => setPrintTicket(!printTicket)}
                className={`relative inline-flex h-7 w-12 items-center rounded-full transition-colors ${
                  printTicket ? "bg-blue-600" : "bg-gray-300"
                }`}
              >
                <span
                  className={`inline-block h-5 w-5 transform rounded-full bg-white transition-transform ${
                    printTicket ? "translate-x-6" : "translate-x-1"
                  }`}
                />
              </button>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="border-t p-6 space-y-3">
            <button
              onClick={handlePayment}
              disabled={!selectedPaymentMethod}
              className="w-full bg-green-600 hover:bg-green-700 disabled:bg-gray-300 disabled:cursor-not-allowed text-white rounded-lg py-4 text-lg font-semibold transition-colors"
            >
              Complete Payment
            </button>
            <button
              onClick={handleCloseWithoutPayment}
              className="w-full bg-white hover:bg-gray-50 border-2 border-gray-300 text-gray-700 rounded-lg py-3 font-medium transition-colors"
            >
              Close without Payment
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
