import { useState } from "react";
import { MobileApp } from "./components/MobileApp";
import { DesktopLogin } from "./components/DesktopLogin";
import { DesktopClients } from "./components/DesktopClients";
import { WireframeControls } from "./components/WireframeControls";
import { Toaster } from "./components/ui/sonner";

export default function App() {
  const [activeView, setActiveView] = useState<
    "mobile" | "desktop"
  >("mobile");
  const [wireframeType, setWireframeType] = useState<
    "general" | "login"
  >("login");
  const [isDesktopLoggedIn, setIsDesktopLoggedIn] =
    useState(false);

  const handleDesktopLogin = () => {
    setIsDesktopLoggedIn(true);
  };

  const handleDesktopLogout = () => {
    setIsDesktopLoggedIn(false);
  };

  const renderComponents = () => {
    if (wireframeType === "login") {
      return {
        mobile: <MobileApp />,
        desktop: isDesktopLoggedIn ? (
          <DesktopClients onLogout={handleDesktopLogout} />
        ) : (
          <DesktopLogin onLogin={handleDesktopLogin} />
        ),
      };
    } else {
      return {
        mobile: <MobileApp />,
        desktop: (
          <DesktopClients onLogout={handleDesktopLogout} />
        ),
      };
    }
  };

  const components = renderComponents();

  return (
    <div className="min-h-screen bg-gray-100">
      {activeView === "mobile" ? (
        // Mobile view with constraints
        <div className="max-w-7xl mx-auto p-6">
          <WireframeControls
            activeView={activeView}
            onViewChange={setActiveView}
            wireframeType={wireframeType}
            onTypeChange={setWireframeType}
          />

          <div className="flex justify-center">
            <div className="flex justify-center">
              <div className="border border-gray-300 rounded-lg overflow-hidden shadow-lg">
                {components.mobile}
              </div>
            </div>
          </div>

          <div className="mt-8 text-center text-sm text-gray-600">
            <p>
              Interactive prototypes for IMU - Itinerary Manager
              Uniformed
            </p>
            <p className="mt-2">
              Toggle between mobile and desktop views to see
              responsive designs
            </p>
          </div>
        </div>
      ) : (
        // Desktop view full-width
        <div className="w-full">
          <div className="max-w-7xl mx-auto px-6 pt-6">
            <WireframeControls
              activeView={activeView}
              onViewChange={setActiveView}
              wireframeType={wireframeType}
              onTypeChange={setWireframeType}
            />
          </div>

          <div className="w-full px-6 pb-6">
            <div className="w-full">{components.desktop}</div>
          </div>

          <div className="max-w-7xl mx-auto px-6 pb-6">
            <div className="text-center text-sm text-gray-600">
              <p>
                Interactive prototypes for IMU - Itinerary
                Manager Uniformed
              </p>
              <p className="mt-2">
                Toggle between mobile and desktop views to see
                responsive designs
              </p>
            </div>
          </div>
        </div>
      )}

      <Toaster />
    </div>
  );
}