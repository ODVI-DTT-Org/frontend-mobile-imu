import { useState } from "react";
import { ArrowLeft, Edit, Trash2, MapPin, Phone, Archive, Eye, Star, User, Building, Package, CreditCard, Hash, Plus } from "lucide-react";
import { Button } from "./ui/button";
import { Badge } from "./ui/badge";
import { MobileStatusBar } from "./MobileStatusBar";
import { Client } from "./MobileClients";
import { TouchpointModal } from "./TouchpointModal";
import { TouchpointArchiveModal } from "./TouchpointArchiveModal";
import { DataService } from "../services/DataService";

interface MobileClientDetailProps {
  client: Client;
  onBack: () => void;
  onNavigateToHome: () => void;
}

interface Touchpoint {
  id: number;
  type: 'Visit' | 'Call';
  date: string;
  notes?: string;
}

export function MobileClientDetail({ client, onBack, onNavigateToHome }: MobileClientDetailProps) {
  const [selectedTouchpoint, setSelectedTouchpoint] = useState<Touchpoint | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isArchiveOpen, setIsArchiveOpen] = useState(false);

  // Get real client data from DataService
  const clientDetails = DataService.getClientDetails(parseInt(client.id));
  
  if (!clientDetails) {
    return <div>Client not found</div>;
  }

  // Create all 7 touchpoints with correct pattern: Visit Call Call Visit Call Call Visit
  const touchpointPattern: ('Visit' | 'Call')[] = ['Visit', 'Call', 'Call', 'Visit', 'Call', 'Call', 'Visit'];
  const maxTouchpoints = 7;
  
  // Create array of all touchpoints (1-7) with proper data mapping
  const allTouchpoints: Touchpoint[] = [];
  for (let i = 0; i < maxTouchpoints; i++) {
    const touchpointNumber = i + 1;
    const visit = clientDetails.visits.find(v => v.Touchpoint === touchpointNumber);
    
    allTouchpoints.push({
      id: touchpointNumber,
      type: touchpointPattern[i],
      date: visit?.DateOfVisit || '',
      notes: visit?.Remarks || ''
    });
  }

  // Number of completed touchpoints (visits that exist)
  const completedTouchpoints = clientDetails.visits.length;

  // Format address
  const primaryAddress = clientDetails.addresses.find(addr => addr.IsDefault) || clientDetails.addresses[0];
  const primaryPhone = clientDetails.phoneNumbers.find(phone => phone.IsPrimary) || clientDetails.phoneNumbers[0];
  const secondaryPhone = clientDetails.phoneNumbers.find(phone => !phone.IsPrimary);

  // Format birthday
  const formatBirthday = (birthday: string) => {
    const date = new Date(birthday);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return `${months[date.getMonth()]} ${date.getDate()}, ${date.getFullYear()}`;
  };

  const getTouchpointIcon = (type: 'Visit' | 'Call', index: number) => {
    // A touchpoint is active if it has been completed (index is within the range of actual visits)
    const isActive = index < completedTouchpoints;
    const iconClass = isActive ? 'text-green-600' : 'text-gray-400';
    
    if (type === 'Visit') {
      return <MapPin className={`w-6 h-6 ${iconClass}`} />;
    } else {
      return <Phone className={`w-6 h-6 ${iconClass}`} />;
    }
  };

  const getOrdinal = (num: number) => {
    const ordinals = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th'];
    return ordinals[num - 1] || `${num}th`;
  };

  return (
    <div className="bg-white flex flex-col h-full overflow-hidden">
      <MobileStatusBar />

      {/* Fixed Header */}
      <div className="flex items-center justify-between px-4 py-3 border-b border-gray-200 bg-white z-10 flex-shrink-0">
        <button onClick={onBack} className="flex items-center">
          <ArrowLeft className="w-5 h-5 text-black mr-2" />
          <span className="text-sm text-gray-600">Back</span>
        </button>
      </div>

      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto min-h-0">
        {/* Client Name and Actions */}
        <div className="px-4 py-4 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-xl text-black">{client.name}</h1>
              <p className="text-sm text-gray-600 mt-1">
                {client.status === 'potential' ? 'Potential' : 'Existing'} Client
              </p>
            </div>
            <div className="flex items-center space-x-2">
              <Button variant="ghost" size="sm">
                <Edit className="w-4 h-4" />
              </Button>
              <Button variant="ghost" size="sm">
                <Trash2 className="w-4 h-4 text-red-500" />
              </Button>
            </div>
          </div>
        </div>

        {/* Touchpoints */}
        <div className="px-4 py-2 border-b border-gray-200">
          <div className="flex items-center justify-between">
            {allTouchpoints.map((touchpoint, index) => {
              const isActive = index < completedTouchpoints; // Only completed touchpoints are active
              return (
                <button
                  key={`touchpoint-${index}`}
                  onClick={() => {
                    if (isActive) {
                      setSelectedTouchpoint(touchpoint);
                      setIsModalOpen(true);
                    }
                  }}
                  disabled={!isActive}
                  className={`flex flex-col items-center space-y-1 p-2 rounded transition-colors ${
                    isActive 
                      ? 'hover:bg-gray-50 cursor-pointer' 
                      : 'cursor-not-allowed opacity-50'
                  }`}
                >
                  {getTouchpointIcon(touchpoint.type, index)}
                  <span className={`text-xs ${isActive ? 'text-gray-600' : 'text-gray-400'}`}>{getOrdinal(index + 1)}</span>
                </button>
              );
            })}
            <button 
              onClick={() => setIsArchiveOpen(true)}
              className="flex flex-col items-center space-y-1 hover:bg-gray-50 p-2 rounded transition-colors"
            >
              <Archive className="w-6 h-6 text-gray-400" />
              <span className="text-xs text-gray-600">Archive</span>
            </button>
          </div>
        </div>



        {/* Client Details */}
        <div className="px-4 py-4 border-b border-gray-200">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-base text-black">Client Details</h3>
            <Button variant="ghost" size="sm">
              <Edit className="w-4 h-4" />
            </Button>
          </div>
          
          <div className="space-y-3">
            <div className="flex items-center space-x-3">
              <User className="w-4 h-4 text-gray-500" />
              <div className="flex items-center space-x-4 flex-1">
                <span className="text-sm text-gray-600 w-16">Age</span>
                <span className="text-sm text-black">{clientDetails.Age}yrs old</span>
              </div>
            </div>
            
            <div className="flex items-center space-x-3">
              <Star className="w-4 h-4 text-gray-500" />
              <div className="flex items-center space-x-4 flex-1">
                <span className="text-sm text-gray-600 w-16">Birthday</span>
                <span className="text-sm text-black">{formatBirthday(clientDetails.Birthday)}</span>
              </div>
            </div>

            <div className="flex items-center space-x-3">
              <Eye className="w-4 h-4 text-gray-500" />
              <div className="flex items-center space-x-4 flex-1">
                <span className="text-sm text-gray-600 w-16">Email</span>
                <span className="text-sm text-black">{clientDetails.Gmail}</span>
              </div>
            </div>

            <div className="flex items-center space-x-3">
              <Star className="w-4 h-4 text-gray-500" />
              <div className="flex items-center space-x-4 flex-1">
                <span className="text-sm text-gray-600 w-16">Facebook</span>
                <span className="text-sm text-black">{clientDetails.FacebookLink}</span>
              </div>
            </div>

            <div className="flex items-center space-x-3">
              <Building className="w-4 h-4 text-gray-500" />
              <div className="flex items-center space-x-4 flex-1">
                <span className="text-sm text-gray-600 w-16">Market</span>
                <span className="text-sm text-black">{client.marketType}</span>
              </div>
            </div>

            <div className="flex items-center space-x-3">
              <Package className="w-4 h-4 text-gray-500" />
              <div className="flex items-center space-x-4 flex-1">
                <span className="text-sm text-gray-600 w-16">Product</span>
                <span className="text-sm text-black">{client.productType}</span>
              </div>
            </div>

            <div className="flex items-center space-x-3">
              <CreditCard className="w-4 h-4 text-gray-500" />
              <div className="flex items-center space-x-4 flex-1">
                <span className="text-sm text-gray-600 w-16">Pension</span>
                <span className="text-sm text-black">{client.pensionType}</span>
              </div>
            </div>

            <div className="flex items-center space-x-3">
              <Hash className="w-4 h-4 text-gray-500" />
              <div className="flex items-center space-x-4 flex-1">
                <span className="text-sm text-gray-600 w-16">PAN</span>
                <span className="text-sm text-black">{clientDetails.PAN}</span>
              </div>
            </div>
          </div>
        </div>

        {/* How to Contact */}
        <div className="px-4 py-4 border-b border-gray-200">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-base text-black">How to contact</h3>
            <Button variant="ghost" size="sm">
              <Edit className="w-4 h-4" />
            </Button>
          </div>
          
          <div className="space-y-3">
            <div className="flex items-center space-x-3">
              <MapPin className="w-4 h-4 text-gray-500" />
              <div>
                <p className="text-sm text-black">{primaryAddress?.Street}</p>
                <p className="text-sm text-gray-600">{primaryAddress?.Municipality}, {primaryAddress?.Province}</p>
              </div>
            </div>
            
            {primaryPhone && (
              <div className="flex items-center space-x-3">
                <Phone className="w-4 h-4 text-gray-500" />
                <span className="text-sm text-black">{primaryPhone.PhoneNumber}</span>
              </div>
            )}
            
            {secondaryPhone && (
              <div className="flex items-center space-x-3">
                <Phone className="w-4 h-4 text-gray-500" />
                <span className="text-sm text-black">{secondaryPhone.PhoneNumber}</span>
              </div>
            )}
          </div>

          <div className="flex space-x-2 mt-4">
            <Button className="flex-1 bg-black text-white">
              <Plus className="w-4 h-4 mr-1" />
              Add Address
            </Button>
            <Button className="flex-1 bg-black text-white">
              <Plus className="w-4 h-4 mr-1" />
              Add Phone Number
            </Button>
          </div>
        </div>


      </div>





      {/* Touchpoint Modal */}
      <TouchpointModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        touchpoint={selectedTouchpoint}
        client={client}
      />

      {/* Archive Modal */}
      <TouchpointArchiveModal
        isOpen={isArchiveOpen}
        onClose={() => setIsArchiveOpen(false)}
        client={client}
        onTouchpointSelect={(touchpoint) => {
          setSelectedTouchpoint(touchpoint);
          setIsModalOpen(true);
        }}
      />
    </div>
  );
}