import { Bell, User, Plus } from "lucide-react";

interface Table {
  id: string;
  number: string;
  status: "available" | "occupied" | "awaiting-payment";
  orderTotal?: number;
}

interface TableLayoutProps {
  onSelectTable: (tableNumber: string) => void;
  tables: Table[];
}

export function TableLayout({ onSelectTable, tables }: TableLayoutProps) {
  const getTableStatusColor = (status: Table["status"]) => {
    switch (status) {
      case "available":
        return "bg-gray-700 hover:bg-gray-600";
      case "occupied":
        return "bg-blue-600 hover:bg-blue-500";
      case "awaiting-payment":
        return "bg-green-600 hover:bg-green-500";
    }
  };

  const getTableStatusText = (status: Table["status"]) => {
    switch (status) {
      case "available":
        return "Available";
      case "occupied":
        return "Occupied";
      case "awaiting-payment":
        return "Awaiting Payment";
    }
  };

  return (
    <div className="flex flex-col h-screen bg-gray-100">
      {/* HEADER */}
      <div className="bg-white border-b shadow-sm">
        <div className="flex items-center justify-between px-6 py-3">
          <div className="flex items-center gap-8">
            <h1 className="text-xl font-semibold text-gray-900">Restaurant POS</h1>
            
            <nav className="flex gap-1">
              <button className="px-4 py-2 text-blue-600 font-medium border-b-2 border-blue-600">
                Floor Plan
              </button>
              <button className="px-4 py-2 text-gray-600 hover:text-gray-900 font-medium">
                Orders
              </button>
              <button className="px-4 py-2 text-gray-600 hover:text-gray-900 font-medium">
                Order History
              </button>
            </nav>
          </div>
          
          <div className="flex items-center gap-4">
            <button className="p-2 rounded-lg hover:bg-gray-100 relative">
              <Bell className="w-5 h-5 text-gray-600" />
              <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
            </button>
            <div className="flex items-center gap-2 px-3 py-2 bg-gray-100 rounded-lg">
              <User className="w-4 h-4 text-gray-600" />
              <span className="text-sm font-medium text-gray-700">Admin User</span>
            </div>
          </div>
        </div>
      </div>

      {/* MAIN CONTENT */}
      <div className="flex-1 overflow-y-auto p-8">
        <div className="max-w-7xl mx-auto">
          {/* New Order Button */}
          <div className="mb-8">
            <button
              onClick={() => onSelectTable("to-go")}
              className="px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-semibold flex items-center gap-2 transition-colors"
            >
              <Plus className="w-5 h-5" />
              New Order (To Go)
            </button>
          </div>

          {/* Legend */}
          <div className="flex gap-6 mb-6">
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 rounded bg-gray-700"></div>
              <span className="text-sm text-gray-600">Available</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 rounded bg-blue-600"></div>
              <span className="text-sm text-gray-600">Occupied</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 rounded bg-green-600"></div>
              <span className="text-sm text-gray-600">Awaiting Payment</span>
            </div>
          </div>

          {/* Floor Plan Title */}
          <h2 className="text-2xl font-semibold text-gray-900 mb-6">Floor Plan</h2>

          {/* Tables Grid */}
          <div className="grid grid-cols-5 gap-6">
            {tables.map(table => (
              <button
                key={table.id}
                onClick={() => onSelectTable(table.number)}
                className={`${getTableStatusColor(
                  table.status
                )} text-white rounded-xl p-6 transition-all transform hover:scale-105 shadow-lg aspect-square flex flex-col items-center justify-center`}
              >
                <div className="text-5xl font-bold mb-2">{table.number}</div>
                <div className="text-sm opacity-90">{getTableStatusText(table.status)}</div>
                {table.orderTotal && table.orderTotal > 0 && (
                  <div className="text-lg font-semibold mt-2">
                    ${table.orderTotal.toFixed(2)}
                  </div>
                )}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
