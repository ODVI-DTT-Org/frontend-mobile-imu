import { Home, Calendar, MapPin } from "lucide-react";

interface MobileBottomNavProps {
  currentScreen: 'home' | 'my-day' | 'itinerary';
  onNavigateToHome: () => void;
  onNavigateToMyDay: () => void;
  onNavigateToItinerary: () => void;
}

export function MobileBottomNav({ 
  currentScreen, 
  onNavigateToHome, 
  onNavigateToMyDay, 
  onNavigateToItinerary 
}: MobileBottomNavProps) {
  const navItems = [
    { 
      key: 'home' as const, 
      icon: Home, 
      label: "Home", 
      onClick: onNavigateToHome 
    },
    { 
      key: 'my-day' as const, 
      icon: Calendar, 
      label: "My Day", 
      onClick: onNavigateToMyDay 
    },
    { 
      key: 'itinerary' as const, 
      icon: MapPin, 
      label: "Itinerary", 
      onClick: onNavigateToItinerary 
    }
  ];

  return (
    <div className="flex items-center justify-around py-4 px-6 border-t border-gray-200 bg-white">
      {navItems.map((item) => {
        const IconComponent = item.icon;
        const isActive = currentScreen === item.key;
        
        return (
          <button
            key={item.key}
            onClick={item.onClick}
            className={`flex flex-col items-center space-y-1 ${
              isActive ? 'text-black' : 'text-gray-400'
            }`}
          >
            <IconComponent className="w-5 h-5" strokeWidth={1.5} />
            <span className="text-xs">{item.label}</span>
          </button>
        );
      })}
    </div>
  );
}