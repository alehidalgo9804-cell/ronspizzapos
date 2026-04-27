import { useState } from "react";
import { 
  ArrowLeft, 
  Bell, 
  Menu, 
  User, 
  UserPlus, 
  Trash2, 
  Send,
  ChevronLeft,
  Plus,
  Minus
} from "lucide-react";
import { ImageWithFallback } from "./figma/ImageWithFallback";

interface Category {
  id: string;
  name: string;
  code: string;
  image: string;
}

interface Product {
  id: string;
  name: string;
  price: number;
  categoryId: string;
}

interface OrderItem extends Product {
  quantity: number;
  guestId: number;
}

interface Guest {
  id: number;
  name: string;
}

interface PosWindowProps {
  tableNumber: string;
  onBackToTables: () => void;
  onProceedToPayment: (total: number) => void;
}

const categories: Category[] = [
  { id: "pizzas", name: "Pizzas", code: "01", image: "https://images.unsplash.com/photo-1679023896894-81b3cc2c24ff?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwaXp6YSUyMHNsaWNlcyUyMGZyZXNofGVufDF8fHx8MTc3MzI5OTk2NHww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" },
  { id: "hamburgers", name: "Hamburgers", code: "02", image: "https://images.unsplash.com/photo-1518185343678-aac7955ef14a?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxoYW1idXJnZXIlMjBnb3VybWV0fGVufDF8fHx8MTc3MzIzMTE5MXww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" },
  { id: "wings", name: "Wings", code: "03", image: "https://images.unsplash.com/photo-1535902491948-06a40e45ed95?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjaGlja2VuJTIwd2luZ3MlMjBwbGF0ZXxlbnwxfHx8fDE3NzMyODk1ODh8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" },
  { id: "boneless", name: "Boneless", code: "04", image: "https://images.unsplash.com/photo-1586793783658-261cddf883ef?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxib25lbGVzcyUyMGNoaWNrZW4lMjBiaXRlc3xlbnwxfHx8fDE3NzMyOTk5NjZ8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" },
  { id: "complements", name: "Complements", code: "05", image: "https://images.unsplash.com/photo-1598679253544-2c97992403ea?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxmcmVuY2glMjBmcmllcyUyMHNpZGVzfGVufDF8fHx8MTc3MzI5OTk2Nnww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" },
  { id: "spaghetti", name: "Spaghetti", code: "06", image: "https://images.unsplash.com/photo-1579584035092-053b2bd1cf12?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzcGFnaGV0dGklMjBwYXN0YSUyMGRpc2h8ZW58MXx8fHwxNzczMTk1Mzk5fDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" },
  { id: "sauces", name: "Sauces", code: "07", image: "https://images.unsplash.com/photo-1633949970279-2680eb2cea23?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb25kaW1lbnQlMjBzYXVjZXMlMjB2YXJpZXR5fGVufDF8fHx8MTc3MzI5OTk2N3ww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" },
  { id: "drinks", name: "Drinks", code: "08", image: "https://images.unsplash.com/photo-1705045206675-01781bf32687?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkcmlua3MlMjBiZXZlcmFnZXMlMjBhc3NvcnRlZHxlbnwxfHx8fDE3NzMyOTk5Njd8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" },
  { id: "promotions", name: "Promotions", code: "09", image: "https://images.unsplash.com/photo-1771477126780-9d7d5fb210f1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxmb29kJTIwcHJvbW90aW9uJTIwc3BlY2lhbHxlbnwxfHx8fDE3NzMyOTk5Njh8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" },
  { id: "extras", name: "Extras", code: "10", image: "https://images.unsplash.com/photo-1724072013765-bb4773d63d6d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkZXNzZXJ0cyUyMGV4dHJhcyUyMHN3ZWV0c3xlbnwxfHx8fDE3NzMyOTk5Njh8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral" },
];

const products: Product[] = [
  // Pizzas
  { id: "p1", name: "Margherita Pizza", price: 12.99, categoryId: "pizzas" },
  { id: "p2", name: "Pepperoni Pizza", price: 14.99, categoryId: "pizzas" },
  { id: "p3", name: "Supreme Pizza", price: 16.99, categoryId: "pizzas" },
  { id: "p4", name: "Hawaiian Pizza", price: 13.99, categoryId: "pizzas" },
  { id: "p5", name: "Meat Lovers Pizza", price: 17.99, categoryId: "pizzas" },
  { id: "p6", name: "Veggie Pizza", price: 13.99, categoryId: "pizzas" },
  
  // Hamburgers
  { id: "h1", name: "Classic Burger", price: 9.99, categoryId: "hamburgers" },
  { id: "h2", name: "Cheeseburger", price: 10.99, categoryId: "hamburgers" },
  { id: "h3", name: "Bacon Burger", price: 11.99, categoryId: "hamburgers" },
  { id: "h4", name: "Double Burger", price: 13.99, categoryId: "hamburgers" },
  { id: "h5", name: "Mushroom Swiss", price: 12.49, categoryId: "hamburgers" },
  { id: "h6", name: "BBQ Burger", price: 11.49, categoryId: "hamburgers" },
  
  // Wings
  { id: "w1", name: "Buffalo Wings (6pc)", price: 8.99, categoryId: "wings" },
  { id: "w2", name: "Buffalo Wings (12pc)", price: 15.99, categoryId: "wings" },
  { id: "w3", name: "BBQ Wings (6pc)", price: 8.99, categoryId: "wings" },
  { id: "w4", name: "BBQ Wings (12pc)", price: 15.99, categoryId: "wings" },
  { id: "w5", name: "Honey Garlic Wings (6pc)", price: 9.49, categoryId: "wings" },
  { id: "w6", name: "Honey Garlic Wings (12pc)", price: 16.99, categoryId: "wings" },
  
  // Boneless
  { id: "b1", name: "Boneless Bites (8pc)", price: 7.99, categoryId: "boneless" },
  { id: "b2", name: "Boneless Bites (16pc)", price: 13.99, categoryId: "boneless" },
  { id: "b3", name: "Spicy Boneless (8pc)", price: 8.49, categoryId: "boneless" },
  { id: "b4", name: "Spicy Boneless (16pc)", price: 14.99, categoryId: "boneless" },
  
  // Complements
  { id: "c1", name: "French Fries", price: 3.99, categoryId: "complements" },
  { id: "c2", name: "Onion Rings", price: 4.49, categoryId: "complements" },
  { id: "c3", name: "Coleslaw", price: 2.99, categoryId: "complements" },
  { id: "c4", name: "Mozzarella Sticks", price: 6.99, categoryId: "complements" },
  { id: "c5", name: "Garlic Bread", price: 4.99, categoryId: "complements" },
  
  // Spaghetti
  { id: "s1", name: "Spaghetti Bolognese", price: 11.99, categoryId: "spaghetti" },
  { id: "s2", name: "Spaghetti Carbonara", price: 12.99, categoryId: "spaghetti" },
  { id: "s3", name: "Spaghetti Marinara", price: 10.99, categoryId: "spaghetti" },
  { id: "s4", name: "Spaghetti Alfredo", price: 12.49, categoryId: "spaghetti" },
  
  // Sauces
  { id: "sa1", name: "Ranch Sauce", price: 0.99, categoryId: "sauces" },
  { id: "sa2", name: "BBQ Sauce", price: 0.99, categoryId: "sauces" },
  { id: "sa3", name: "Hot Sauce", price: 0.99, categoryId: "sauces" },
  { id: "sa4", name: "Garlic Mayo", price: 1.29, categoryId: "sauces" },
  
  // Drinks
  { id: "d1", name: "Coca Cola", price: 2.49, categoryId: "drinks" },
  { id: "d2", name: "Sprite", price: 2.49, categoryId: "drinks" },
  { id: "d3", name: "Fanta", price: 2.49, categoryId: "drinks" },
  { id: "d4", name: "Iced Tea", price: 2.99, categoryId: "drinks" },
  { id: "d5", name: "Lemonade", price: 2.99, categoryId: "drinks" },
  { id: "d6", name: "Water", price: 1.99, categoryId: "drinks" },
  
  // Promotions
  { id: "pr1", name: "Combo Meal #1", price: 19.99, categoryId: "promotions" },
  { id: "pr2", name: "Combo Meal #2", price: 22.99, categoryId: "promotions" },
  { id: "pr3", name: "Family Pack", price: 39.99, categoryId: "promotions" },
  
  // Extras
  { id: "e1", name: "Extra Cheese", price: 1.99, categoryId: "extras" },
  { id: "e2", name: "Extra Bacon", price: 2.49, categoryId: "extras" },
  { id: "e3", name: "Extra Sauce", price: 0.99, categoryId: "extras" },
];

export function PosWindow({ tableNumber, onBackToTables, onProceedToPayment }: PosWindowProps) {
  const [activeTab, setActiveTab] = useState<"receipt" | "client" | "togo">("receipt");
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
  const [orderItems, setOrderItems] = useState<OrderItem[]>([]);
  const [guests, setGuests] = useState<Guest[]>([{ id: 1, name: "Guest 1" }]);
  const [currentGuest, setCurrentGuest] = useState(1);

  const ticketNumber = "12345";

  const addGuest = () => {
    const newGuestId = guests.length + 1;
    setGuests([...guests, { id: newGuestId, name: `Guest ${newGuestId}` }]);
    setCurrentGuest(newGuestId);
  };

  const addToOrder = (product: Product) => {
    setOrderItems(prevItems => {
      const existingItem = prevItems.find(
        item => item.id === product.id && item.guestId === currentGuest
      );
      if (existingItem) {
        return prevItems.map(item =>
          item.id === product.id && item.guestId === currentGuest
            ? { ...item, quantity: item.quantity + 1 }
            : item
        );
      }
      return [...prevItems, { ...product, quantity: 1, guestId: currentGuest }];
    });
  };

  const updateQuantity = (itemId: string, guestId: number, change: number) => {
    setOrderItems(prevItems =>
      prevItems
        .map(item =>
          item.id === itemId && item.guestId === guestId
            ? { ...item, quantity: Math.max(0, item.quantity + change) }
            : item
        )
        .filter(item => item.quantity > 0)
    );
  };

  const removeItem = (itemId: string, guestId: number) => {
    setOrderItems(prevItems =>
      prevItems.filter(item => !(item.id === itemId && item.guestId === guestId))
    );
  };

  const sendToKitchen = () => {
    alert("Order sent to kitchen!");
  };

  const handlePayment = () => {
    onProceedToPayment(orderTotal);
    setOrderItems([]);
    setGuests([{ id: 1, name: "Guest 1" }]);
    setCurrentGuest(1);
  };

  const orderTotal = orderItems.reduce(
    (sum, item) => sum + item.price * item.quantity,
    0
  );

  const categoryProducts = selectedCategory
    ? products.filter(p => p.categoryId === selectedCategory)
    : [];

  return (
    <div className="flex flex-col h-screen bg-gray-100">
      {/* TOP HEADER */}
      <div className="bg-white border-b shadow-sm">
        <div className="flex items-center justify-between px-6 py-3">
          <div className="flex items-center gap-6">
            <button className="flex items-center gap-2 text-gray-700 hover:text-gray-900 px-3 py-2 rounded-lg hover:bg-gray-100" onClick={onBackToTables}>
              <ArrowLeft className="w-5 h-5" />
              <span className="font-medium">Back to Tables</span>
            </button>
            
            <div className="flex gap-1 bg-gray-100 rounded-lg p-1">
              <button
                onClick={() => setActiveTab("receipt")}
                className={`px-6 py-2 rounded-md font-medium transition-colors ${
                  activeTab === "receipt"
                    ? "bg-white text-gray-900 shadow-sm"
                    : "text-gray-600 hover:text-gray-900"
                }`}
              >
                Receipt
              </button>
              <button
                onClick={() => setActiveTab("client")}
                className={`px-6 py-2 rounded-md font-medium transition-colors ${
                  activeTab === "client"
                    ? "bg-white text-gray-900 shadow-sm"
                    : "text-gray-600 hover:text-gray-900"
                }`}
              >
                Client
              </button>
              <button
                onClick={() => setActiveTab("togo")}
                className={`px-6 py-2 rounded-md font-medium transition-colors ${
                  activeTab === "togo"
                    ? "bg-white text-gray-900 shadow-sm"
                    : "text-gray-600 hover:text-gray-900"
                }`}
              >
                To Go
              </button>
            </div>
            
            <div className="text-gray-600">
              Table: <span className="font-semibold text-gray-900">{tableNumber}</span>
              <span className="mx-2">|</span>
              Ticket: <span className="font-semibold text-gray-900">#{ticketNumber}</span>
            </div>
          </div>
          
          <div className="flex items-center gap-4">
            <button className="p-2 rounded-lg hover:bg-gray-100 relative">
              <Bell className="w-5 h-5 text-gray-600" />
              <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
            </button>
            <button className="p-2 rounded-lg hover:bg-gray-100">
              <Menu className="w-5 h-5 text-gray-600" />
            </button>
            <div className="flex items-center gap-2 px-3 py-2 bg-gray-100 rounded-lg">
              <User className="w-4 h-4 text-gray-600" />
              <span className="text-sm font-medium text-gray-700">Admin User</span>
            </div>
          </div>
        </div>
      </div>

      {/* MAIN CONTENT */}
      <div className="flex flex-1 overflow-hidden">
        {/* LEFT PANEL - Order Panel */}
        <div className="w-[450px] bg-white border-r flex flex-col">
          <div className="p-4 border-b">
            <h2 className="font-semibold text-lg text-gray-900">Current Order</h2>
          </div>

          {/* Guest Tabs */}
          <div className="flex gap-2 px-4 py-3 bg-gray-50 border-b overflow-x-auto">
            {guests.map(guest => (
              <button
                key={guest.id}
                onClick={() => setCurrentGuest(guest.id)}
                className={`px-4 py-2 rounded-lg font-medium whitespace-nowrap transition-colors ${
                  currentGuest === guest.id
                    ? "bg-blue-600 text-white"
                    : "bg-white text-gray-700 hover:bg-gray-100"
                }`}
              >
                {guest.name}
              </button>
            ))}
            <button
              onClick={addGuest}
              className="px-4 py-2 rounded-lg bg-white text-blue-600 hover:bg-blue-50 font-medium flex items-center gap-2 whitespace-nowrap"
            >
              <UserPlus className="w-4 h-4" />
              Add Guest
            </button>
          </div>

          {/* Order Items Table */}
          <div className="flex-1 overflow-y-auto">
            {orderItems.length === 0 ? (
              <div className="flex items-center justify-center h-full text-gray-400">
                <p>No items in order</p>
              </div>
            ) : (
              <table className="w-full">
                <thead className="bg-gray-50 sticky top-0">
                  <tr className="text-left text-sm text-gray-600">
                    <th className="px-4 py-3 font-medium">Name</th>
                    <th className="px-4 py-3 font-medium text-center">Qty</th>
                    <th className="px-4 py-3 font-medium text-right">Price</th>
                    <th className="px-4 py-3 font-medium text-right">Total</th>
                    <th className="px-4 py-3 font-medium"></th>
                  </tr>
                </thead>
                <tbody>
                  {guests.map(guest => {
                    const guestItems = orderItems.filter(item => item.guestId === guest.id);
                    if (guestItems.length === 0) return null;
                    
                    return (
                      <tbody key={guest.id}>
                        {guests.length > 1 && (
                          <tr className="bg-blue-50">
                            <td colSpan={5} className="px-4 py-2 text-sm font-semibold text-blue-900">
                              {guest.name}
                            </td>
                          </tr>
                        )}
                        {guestItems.map(item => (
                          <tr key={`${item.id}-${item.guestId}`} className="border-b hover:bg-gray-50">
                            <td className="px-4 py-3 text-sm text-gray-900">{item.name}</td>
                            <td className="px-4 py-3">
                              <div className="flex items-center justify-center gap-1">
                                <button
                                  onClick={() => updateQuantity(item.id, item.guestId, -1)}
                                  className="w-6 h-6 rounded bg-gray-100 hover:bg-gray-200 flex items-center justify-center"
                                >
                                  <Minus className="w-3 h-3" />
                                </button>
                                <span className="w-8 text-center text-sm font-medium">{item.quantity}</span>
                                <button
                                  onClick={() => updateQuantity(item.id, item.guestId, 1)}
                                  className="w-6 h-6 rounded bg-gray-100 hover:bg-gray-200 flex items-center justify-center"
                                >
                                  <Plus className="w-3 h-3" />
                                </button>
                              </div>
                            </td>
                            <td className="px-4 py-3 text-sm text-gray-600 text-right">
                              ${item.price.toFixed(2)}
                            </td>
                            <td className="px-4 py-3 text-sm font-medium text-gray-900 text-right">
                              ${(item.price * item.quantity).toFixed(2)}
                            </td>
                            <td className="px-4 py-3">
                              <button
                                onClick={() => removeItem(item.id, item.guestId)}
                                className="p-1 rounded hover:bg-red-50 text-red-600"
                              >
                                <Trash2 className="w-4 h-4" />
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    );
                  })}
                </tbody>
              </table>
            )}
          </div>

          {/* Order Actions */}
          <div className="border-t p-4 space-y-3">
            <div className="flex justify-between items-center text-xl font-semibold">
              <span>Total:</span>
              <span>${orderTotal.toFixed(2)}</span>
            </div>
            
            <div className="grid grid-cols-2 gap-2">
              <button
                onClick={sendToKitchen}
                disabled={orderItems.length === 0}
                className="px-4 py-3 bg-orange-500 hover:bg-orange-600 disabled:bg-gray-300 disabled:cursor-not-allowed text-white rounded-lg font-medium flex items-center justify-center gap-2 transition-colors"
              >
                <Send className="w-4 h-4" />
                Send to Kitchen
              </button>
              <button
                onClick={handlePayment}
                disabled={orderItems.length === 0}
                className="px-4 py-3 bg-green-600 hover:bg-green-700 disabled:bg-gray-300 disabled:cursor-not-allowed text-white rounded-lg font-medium transition-colors"
              >
                Pay
              </button>
            </div>
          </div>
        </div>

        {/* RIGHT PANEL - Product Selection */}
        <div className="flex-1 bg-gray-100 overflow-y-auto p-6">
          {selectedCategory === null ? (
            // Category Grid
            <div className="grid grid-cols-3 gap-4">
              {categories.map(category => (
                <button
                  key={category.id}
                  onClick={() => setSelectedCategory(category.id)}
                  className="bg-white rounded-xl overflow-hidden shadow-sm hover:shadow-lg transition-all transform hover:scale-105 aspect-square flex flex-col"
                >
                  <div className="flex-1 relative overflow-hidden">
                    <ImageWithFallback
                      src={category.image}
                      alt={category.name}
                      className="w-full h-full object-cover"
                    />
                  </div>
                  <div className="p-4 bg-white">
                    <div className="text-sm text-gray-500 mb-1">{category.code}</div>
                    <div className="font-semibold text-lg text-gray-900">{category.name}</div>
                  </div>
                </button>
              ))}
            </div>
          ) : (
            // Product Grid
            <div>
              <div className="flex items-center gap-4 mb-6">
                <button
                  onClick={() => setSelectedCategory(null)}
                  className="flex items-center gap-2 px-4 py-2 bg-white rounded-lg hover:bg-gray-50 font-medium text-gray-700"
                >
                  <ChevronLeft className="w-5 h-5" />
                  Back to Categories
                </button>
                <h2 className="text-2xl font-semibold text-gray-900">
                  {categories.find(c => c.id === selectedCategory)?.name}
                </h2>
              </div>
              
              <div className="grid grid-cols-4 gap-4">
                {categoryProducts.map(product => (
                  <button
                    key={product.id}
                    onClick={() => addToOrder(product)}
                    className="bg-white rounded-lg p-6 shadow-sm hover:shadow-lg transition-all transform hover:scale-105 flex flex-col items-center justify-center aspect-square"
                  >
                    <div className="text-center">
                      <div className="font-semibold text-gray-900 mb-2">{product.name}</div>
                      <div className="text-2xl font-bold text-blue-600">
                        ${product.price.toFixed(2)}
                      </div>
                    </div>
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}