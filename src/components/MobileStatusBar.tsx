import { Battery, Wifi, Signal } from "lucide-react";

export function MobileStatusBar() {
  return (
    <div className="flex items-center justify-between px-4 py-2 bg-white text-black text-sm">
      {/* Left side - Carrier info */}
      <div className="flex items-center space-x-1">
        <Signal className="w-3 h-3" />
        <span className="text-xs">Carrier</span>
        <Wifi className="w-3 h-3" />
      </div>
      
      {/* Center - Time */}
      <span className="font-medium">8:30 AM</span>
      
      {/* Right side - Battery and signal */}
      <div className="flex items-center space-x-1">
        <span className="text-xs">100%</span>
        <Battery className="w-4 h-4 fill-current" />
      </div>
    </div>
  );
}