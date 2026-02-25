import { useState } from "react";
import { Calendar } from "lucide-react";
import { MobileLogin } from "./MobileLogin";
import { MobileForgotPassword } from "./MobileForgotPassword";
import { MobileResetSent } from "./MobileResetSent";
import { MobileHome } from "./MobileHome";
import { MobileClients, Client } from "./MobileClients";
import { MobileClientDetail } from "./MobileClientDetail";
import { AddClientPage } from "./AddClientPage";
import { MobileItinerary } from "./MobileItinerary";
import { MobileBottomNav } from "./MobileBottomNav";

type MobileScreen = 'login' | 'forgot-password' | 'reset-sent' | 'home' | 'clients' | 'client-detail' | 'add-client' | 'itinerary' | 'my-day';

type BottomNavScreen = 'home' | 'my-day' | 'itinerary';

export function MobileApp() {
  const [currentScreen, setCurrentScreen] = useState<MobileScreen>('login');
  const [selectedClient, setSelectedClient] = useState<Client | null>(null);

  const handleForgotPassword = () => {
    setCurrentScreen('forgot-password');
  };

  const handleResetSent = () => {
    setCurrentScreen('reset-sent');
  };

  const handleBackToLogin = () => {
    setCurrentScreen('login');
  };

  const handleLoginSuccess = () => {
    setCurrentScreen('home');
  };

  const handleNavigateToClients = () => {
    setCurrentScreen('clients');
  };

  const handleBackToHome = () => {
    setCurrentScreen('home');
  };

  const handleClientSelect = (client: Client) => {
    setSelectedClient(client);
    setCurrentScreen('client-detail');
  };

  const handleBackToClients = () => {
    setCurrentScreen('clients');
  };

  const handleNavigateToAddClient = () => {
    setCurrentScreen('add-client');
  };

  const handleClientAdded = () => {
    setCurrentScreen('clients');
  };

  const handleNavigateToItinerary = () => {
    setCurrentScreen('itinerary');
  };

  const handleNavigateToMyDay = () => {
    setCurrentScreen('my-day');
  };

  // Helper function to determine current bottom nav screen
  const getCurrentBottomNavScreen = (): BottomNavScreen | null => {
    switch (currentScreen) {
      case 'home':
      case 'clients':
      case 'client-detail':
      case 'add-client':
        return 'home';
      case 'my-day':
        return 'my-day';
      case 'itinerary':
        return 'itinerary';
      default:
        return null;
    }
  };

  // Helper function to check if we should show bottom nav
  const shouldShowBottomNav = (): boolean => {
    return ['home', 'clients', 'client-detail', 'add-client', 'my-day', 'itinerary'].includes(currentScreen);
  };

  switch (currentScreen) {
    case 'login':
      return (
        <MobileLogin 
          onForgotPassword={handleForgotPassword}
          onLoginSuccess={handleLoginSuccess}
        />
      );
    case 'forgot-password':
      return (
        <MobileForgotPassword 
          onBack={handleBackToLogin}
          onResetSent={handleResetSent}
        />
      );
    case 'reset-sent':
      return (
        <MobileResetSent 
          onBack={handleBackToLogin}
        />
      );
    case 'home':
      return (
        <div className="w-[375px] h-[812px] flex flex-col overflow-hidden">
          <div className="flex-1 max-h-[calc(100%-80px)] overflow-hidden">
            <MobileHome onNavigateToClients={handleNavigateToClients} />
          </div>
          {shouldShowBottomNav() && (
            <MobileBottomNav
              currentScreen={getCurrentBottomNavScreen()!}
              onNavigateToHome={handleBackToHome}
              onNavigateToMyDay={handleNavigateToMyDay}
              onNavigateToItinerary={handleNavigateToItinerary}
            />
          )}
        </div>
      );
    case 'clients':
      return (
        <div className="w-[375px] h-[812px] flex flex-col overflow-hidden">
          <div className="flex-1 max-h-[calc(100%-80px)] overflow-hidden">
            <MobileClients onBack={handleBackToHome} onClientSelect={handleClientSelect} onNavigateToAddClient={handleNavigateToAddClient} />
          </div>
          {shouldShowBottomNav() && (
            <MobileBottomNav
              currentScreen={getCurrentBottomNavScreen()!}
              onNavigateToHome={handleBackToHome}
              onNavigateToMyDay={handleNavigateToMyDay}
              onNavigateToItinerary={handleNavigateToItinerary}
            />
          )}
        </div>
      );
    case 'client-detail':
      return selectedClient ? (
        <div className="w-[375px] h-[812px] flex flex-col overflow-hidden">
          <div className="flex-1 max-h-[calc(100%-80px)] overflow-hidden">
            <MobileClientDetail client={selectedClient} onBack={handleBackToClients} onNavigateToHome={handleBackToHome} />
          </div>
          {shouldShowBottomNav() && (
            <MobileBottomNav
              currentScreen={getCurrentBottomNavScreen()!}
              onNavigateToHome={handleBackToHome}
              onNavigateToMyDay={handleNavigateToMyDay}
              onNavigateToItinerary={handleNavigateToItinerary}
            />
          )}
        </div>
      ) : null;
    case 'add-client':
      return (
        <div className="w-[375px] h-[812px] flex flex-col overflow-hidden">
          <div className="flex-1 max-h-[calc(100%-80px)] overflow-hidden">
            <AddClientPage onBack={handleBackToClients} onClientAdded={handleClientAdded} />
          </div>
          {shouldShowBottomNav() && (
            <MobileBottomNav
              currentScreen={getCurrentBottomNavScreen()!}
              onNavigateToHome={handleBackToHome}
              onNavigateToMyDay={handleNavigateToMyDay}
              onNavigateToItinerary={handleNavigateToItinerary}
            />
          )}
        </div>
      );
    case 'itinerary':
      return (
        <div className="w-[375px] h-[812px] flex flex-col overflow-hidden">
          <div className="flex-1 max-h-[calc(100%-80px)] overflow-hidden">
            <MobileItinerary />
          </div>
          {shouldShowBottomNav() && (
            <MobileBottomNav
              currentScreen={getCurrentBottomNavScreen()!}
              onNavigateToHome={handleBackToHome}
              onNavigateToMyDay={handleNavigateToMyDay}
              onNavigateToItinerary={handleNavigateToItinerary}
            />
          )}
        </div>
      );
    case 'my-day':
      return (
        <div className="w-[375px] h-[812px] flex flex-col overflow-hidden">
          <div className="flex-1 max-h-[calc(100%-80px)] overflow-hidden flex items-center justify-center bg-white">
            <div className="text-center">
              <Calendar className="w-12 h-12 text-gray-400 mx-auto mb-4" />
              <h2 className="text-lg text-black mb-2">My Day</h2>
              <p className="text-gray-500">Coming soon...</p>
            </div>
          </div>
          {shouldShowBottomNav() && (
            <MobileBottomNav
              currentScreen={getCurrentBottomNavScreen()!}
              onNavigateToHome={handleBackToHome}
              onNavigateToMyDay={handleNavigateToMyDay}
              onNavigateToItinerary={handleNavigateToItinerary}
            />
          )}
        </div>
      );
    default:
      return (
        <MobileLogin 
          onForgotPassword={handleForgotPassword}
          onLoginSuccess={handleLoginSuccess}
        />
      );
  }
}