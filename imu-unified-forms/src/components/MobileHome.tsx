import { 
  Users, 
  Target, 
  MapPin, 
  Calculator, 
  ClipboardList, 
  User,
  Home,
  Calendar
} from "lucide-react";
import { MobileStatusBar } from "./MobileStatusBar";

interface MobileHomeProps {
  onNavigateToClients: () => void;
}

export function MobileHome({ onNavigateToClients }: MobileHomeProps) {
  const menuItems = [
    { icon: Users, label: "My Clients", id: "clients", onClick: onNavigateToClients },
    { icon: Target, label: "My Targets", id: "targets" },
    { icon: MapPin, label: "Missed Visits", id: "visits" },
    { icon: Calculator, label: "Loan Calculator", id: "calculator" },
    { icon: ClipboardList, label: "Attendance", id: "attendance" },
    { icon: User, label: "My Profile", id: "profile" }
  ];

  return (
    <div className="bg-white flex flex-col h-full overflow-hidden">
      {/* Status Bar */}
      <MobileStatusBar />

      {/* Main Content */}
      <div className="flex-1 px-6 py-8 overflow-y-auto min-h-0">
        {/* Greeting */}
        <div className="mb-12">
          <h1 className="text-2xl text-black">Good Day, JC!</h1>
        </div>

        {/* Menu Grid */}
        <div className="grid grid-cols-2 gap-8">
          {menuItems.map((item) => {
            const IconComponent = item.icon;
            return (
              <button
                key={item.id}
                onClick={item.onClick || (() => {})}
                className="flex flex-col items-center space-y-3 p-4 hover:bg-gray-50 rounded-lg transition-colors"
              >
                <div className="w-12 h-12 flex items-center justify-center">
                  <IconComponent className="w-8 h-8 text-black" strokeWidth={1.5} />
                </div>
                <span className="text-black text-sm text-center leading-tight">
                  {item.label}
                </span>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}