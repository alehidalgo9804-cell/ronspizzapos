import { useState } from "react";
import { PosWindow } from "./components/pos-window";
import { TableLayout } from "./components/table-layout";
import { PaymentScreen } from "./components/payment-screen";

interface Table {
  id: string;
  number: string;
  status: "available" | "occupied" | "awaiting-payment";
  orderTotal?: number;
}

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<"tables" | "pos" | "payment">("tables");
  const [selectedTable, setSelectedTable] = useState<string | null>(null);
  const [paymentTotal, setPaymentTotal] = useState(0);
  const [ticketNumber, setTicketNumber] = useState("12345");
  const [tables, setTables] = useState<Table[]>([
    { id: "1", number: "1", status: "available" },
    { id: "2", number: "2", status: "available" },
    { id: "3", number: "3", status: "occupied", orderTotal: 45.50 },
    { id: "4", number: "4", status: "available" },
    { id: "5", number: "5", status: "awaiting-payment", orderTotal: 78.25 },
    { id: "6", number: "6", status: "available" },
    { id: "7", number: "7", status: "occupied", orderTotal: 32.00 },
    { id: "8", number: "8", status: "available" },
    { id: "9", number: "9", status: "available" },
    { id: "12", number: "1 y 2", status: "available" },
    { id: "34", number: "3 y 4", status: "available" },
    { id: "10", number: "10", status: "available" },
    { id: "11", number: "11", status: "available" },
    { id: "12a", number: "12", status: "available" },
    { id: "13", number: "13", status: "available" },
  ]);

  const handleSelectTable = (tableNumber: string) => {
    setSelectedTable(tableNumber);
    setCurrentScreen("pos");
  };

  const handleBackToTables = () => {
    setCurrentScreen("tables");
    setSelectedTable(null);
  };

  const handleProceedToPayment = (total: number) => {
    setPaymentTotal(total);
    setCurrentScreen("payment");
  };

  const handlePaymentComplete = () => {
    // Update table status to available and reset order
    setCurrentScreen("tables");
    setSelectedTable(null);
    setPaymentTotal(0);
  };

  const handlePaymentCancel = () => {
    setCurrentScreen("pos");
  };

  return (
    <div className="size-full">
      {currentScreen === "tables" ? (
        <TableLayout onSelectTable={handleSelectTable} tables={tables} />
      ) : currentScreen === "pos" ? (
        <PosWindow 
          tableNumber={selectedTable || "1"} 
          onBackToTables={handleBackToTables}
          onProceedToPayment={handleProceedToPayment}
        />
      ) : (
        <PaymentScreen
          ticketNumber={ticketNumber}
          tableNumber={selectedTable || "1"}
          orderTotal={paymentTotal}
          onCancel={handlePaymentCancel}
          onComplete={handlePaymentComplete}
        />
      )}
    </div>
  );
}