import { useState, useEffect } from "react";
import { ArrowLeft, Filter, Star, Search, Plus, Phone, MapPin } from "lucide-react";
import { Input } from "./ui/input";
import { Button } from "./ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogTrigger } from "./ui/dialog";
import { Badge } from "./ui/badge";
import { Tabs, TabsList, TabsTrigger } from "./ui/tabs";
import { MobileStatusBar } from "./MobileStatusBar";
import { DataService, ClientDetails } from "../services/DataService";

export interface Client {
  id: string;
  name: string;
  productType: string;
  marketType: string;
  clientType: string;
  pensionType: string;
  status: 'potential' | 'existing';
  remarks: string; // Allow any string for the actual touchpoint reason
  touchpointProgress: number; // Number of completed touchpoints (1-7)
  latestTouchpointReason?: string; // Latest touchpoint reason
  latestTouchpointNumber?: number; // Latest touchpoint number (1-7)
  latestTouchpointDate?: string; // Latest touchpoint date
}

interface MobileClientsProps {
  onBack: () => void;
  onClientSelect: (client: Client) => void;
  onNavigateToAddClient: () => void;
}

export function MobileClients({ onBack, onClientSelect, onNavigateToAddClient }: MobileClientsProps) {
  const [searchQuery, setSearchQuery] = useState("");
  const [showInterested, setShowInterested] = useState(false);
  const [activeTab, setActiveTab] = useState<'POTENTIAL' | 'EXISTING'>('POTENTIAL');
  const [marketTypeFilter, setMarketTypeFilter] = useState<string[]>([]);
  const [productTypeFilter, setProductTypeFilter] = useState<string[]>([]);
  const [pensionTypeFilter, setPensionTypeFilter] = useState<string[]>([]);
  const [reasonFilter, setReasonFilter] = useState<string[]>([]);
  const [refreshKey, setRefreshKey] = useState(0);

  // Force refresh when component mounts (useful when returning from add client page)
  useEffect(() => {
    setRefreshKey(prev => prev + 1);
  }, []);

  // Get data from DataService
  const rawClients = DataService.getAllClientDetails();
  const reasons = DataService.getReasons();
  const marketTypes = DataService.getMarketTypes();
  const productTypes = DataService.getProductTypes();
  const pensionTypes = DataService.getPensionTypes();

  // Helper functions for filter management
  const toggleFilter = (filterArray: string[], value: string): string[] => {
    if (filterArray.includes(value)) {
      return filterArray.filter(item => item !== value);
    } else {
      return [...filterArray, value];
    }
  };

  const clearAllFilters = () => {
    setMarketTypeFilter([]);
    setProductTypeFilter([]);
    setPensionTypeFilter([]);
    setReasonFilter([]);
  };

  // Helper function to get touchpoint icon based on touchpoint pattern
  const getTouchpointIcon = (touchpointNumber: number) => {
    // Pattern: Visit Call Call Visit Call Call Visit (positions 1-7)
    const touchpointPattern = ['Visit', 'Call', 'Call', 'Visit', 'Call', 'Call', 'Visit'];
    const type = touchpointPattern[touchpointNumber - 1] || 'Visit';
    
    if (type === 'Visit') {
      return <MapPin className="w-3 h-3" />;
    } else {
      return <Phone className="w-3 h-3" />;
    }
  };

  // Helper function to get ordinal number
  const getOrdinal = (num: number) => {
    const ordinals = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th'];
    return ordinals[num - 1] || `${num}th`;
  };

  // Helper function to format date
  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return `${months[date.getMonth()]} ${date.getDate()}`;
  };

  // Convert ClientDetails to Client interface for compatibility with existing UI
  const convertToClientInterface = (clientDetail: ClientDetails): Client => {
    // Use the actual reason from the latest touchpoint, with proper formatting
    const formatReason = (reason?: string): string => {
      if (!reason) return 'NO ACTIVITY';
      
      // Convert to title case and replace underscores
      return reason
        .toLowerCase()
        .split(' ')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1))
        .join(' ');
    };

    // Find the latest touchpoint (highest touchpoint number) to get its reason and date
    const latestVisit = clientDetail.visits.length > 0 
      ? clientDetail.visits.reduce((latest, current) => 
          current.Touchpoint > latest.Touchpoint ? current : latest
        )
      : null;

    const latestTouchpointReason = latestVisit?.Reason || null;
    const formattedReason = formatReason(latestTouchpointReason);

    return {
      id: clientDetail.ClientID.toString(),
      name: clientDetail.FullName,
      productType: clientDetail.ProductType,
      marketType: clientDetail.MarketType,
      clientType: clientDetail.ClientType,
      pensionType: clientDetail.PensionType,
      status: clientDetail.ClientType === 'EXISTING' ? 'existing' : 'potential',
      remarks: formattedReason as any, // Use the latest touchpoint's reason
      touchpointProgress: clientDetail.visits.length, // Use actual visit count as touchpoint progress
      latestTouchpointReason: latestTouchpointReason,
      latestTouchpointNumber: latestVisit?.Touchpoint || 0, // Add touchpoint number
      latestTouchpointDate: latestVisit?.DateOfVisit || undefined // Add touchpoint date
    };
  };

  // Convert all clients and sort alphabetically by name
  const clients: Client[] = rawClients
    .map(convertToClientInterface)
    .sort((a, b) => a.name.localeCompare(b.name));

  const filteredClients = clients.filter(client => {
    const matchesSearch = client.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         client.productType.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesInterested = !showInterested || client.latestTouchpointReason === 'INTERESTED';
    const matchesTab = client.clientType === activeTab;
    const matchesMarketType = marketTypeFilter.length === 0 || marketTypeFilter.includes(client.marketType);
    const matchesProductType = productTypeFilter.length === 0 || productTypeFilter.includes(client.productType);
    const matchesPensionType = pensionTypeFilter.length === 0 || pensionTypeFilter.includes(client.pensionType);
    const matchesReason = reasonFilter.length === 0 || reasonFilter.includes(client.latestTouchpointReason || 'NO ACTIVITY');
    
    return matchesSearch && matchesInterested && matchesTab && matchesMarketType && matchesProductType && matchesPensionType && matchesReason;
  });

  return (
    <div className="bg-white flex flex-col h-full overflow-hidden">
      <MobileStatusBar />

      {/* Fixed Header */}
      <div className="flex items-center justify-between px-4 py-3 border-b border-gray-200 bg-white z-10 flex-shrink-0">
        <button onClick={onBack} className="flex items-center">
          <ArrowLeft className="w-5 h-5 text-black mr-2" />
          <span className="text-sm text-gray-600">Home</span>
        </button>
        <h1 className="flex-1 text-center text-lg text-black">My Clients</h1>
        <div className="w-8" />
      </div>

      {/* Fixed Search and Filter */}
      <div className="px-4 py-3 border-b border-gray-200 space-y-3 bg-white z-10 flex-shrink-0">
        <div className="flex items-center space-x-2">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
            <Input
              placeholder="Search clients..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10"
            />
          </div>
          <Dialog>
            <DialogTrigger asChild>
              <Button variant="outline" size="sm">
                <Filter className="w-4 h-4" />
              </Button>
            </DialogTrigger>
            <DialogContent className="w-[300px] max-h-[80vh] overflow-y-auto">
              <DialogHeader>
                <DialogTitle>Filter Options</DialogTitle>
                <DialogDescription>
                  Filter clients by market type, product type, pension type, and reason.
                </DialogDescription>
              </DialogHeader>
              <div className="space-y-4">
                <div className="flex justify-end">
                  <Button variant="outline" size="sm" onClick={clearAllFilters}>
                    Clear Filters
                  </Button>
                </div>
                
                <div>
                  <label className="text-sm font-medium">Market Type</label>
                  <div className="space-y-2 mt-2">
                    {marketTypes.map(type => (
                      <div key={type} className="flex items-center space-x-2">
                        <input
                          type="checkbox"
                          id={`market-${type}`}
                          checked={marketTypeFilter.includes(type)}
                          onChange={() => setMarketTypeFilter(toggleFilter(marketTypeFilter, type))}
                          className="rounded border-gray-300"
                        />
                        <label htmlFor={`market-${type}`} className="text-sm">{type}</label>
                      </div>
                    ))}
                  </div>
                </div>
                
                <div>
                  <label className="text-sm font-medium">Product Type</label>
                  <div className="space-y-2 mt-2">
                    {productTypes.map(type => (
                      <div key={type} className="flex items-center space-x-2">
                        <input
                          type="checkbox"
                          id={`product-${type}`}
                          checked={productTypeFilter.includes(type)}
                          onChange={() => setProductTypeFilter(toggleFilter(productTypeFilter, type))}
                          className="rounded border-gray-300"
                        />
                        <label htmlFor={`product-${type}`} className="text-sm">{type}</label>
                      </div>
                    ))}
                  </div>
                </div>
                
                <div>
                  <label className="text-sm font-medium">Pension Type</label>
                  <div className="space-y-2 mt-2">
                    {pensionTypes.map(type => (
                      <div key={type} className="flex items-center space-x-2">
                        <input
                          type="checkbox"
                          id={`pension-${type}`}
                          checked={pensionTypeFilter.includes(type)}
                          onChange={() => setPensionTypeFilter(toggleFilter(pensionTypeFilter, type))}
                          className="rounded border-gray-300"
                        />
                        <label htmlFor={`pension-${type}`} className="text-sm">{type}</label>
                      </div>
                    ))}
                  </div>
                </div>
                
                <div>
                  <label className="text-sm font-medium">Reason</label>
                  <div className="space-y-2 mt-2">
                    {reasons.map(reason => (
                      <div key={reason} className="flex items-center space-x-2">
                        <input
                          type="checkbox"
                          id={`reason-${reason}`}
                          checked={reasonFilter.includes(reason)}
                          onChange={() => setReasonFilter(toggleFilter(reasonFilter, reason))}
                          className="rounded border-gray-300"
                        />
                        <label htmlFor={`reason-${reason}`} className="text-sm">{reason}</label>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </DialogContent>
          </Dialog>
          
          {/* Interested Filter Button - Star icon only */}
          <Button
            variant={showInterested ? "default" : "outline"}
            size="sm"
            onClick={() => setShowInterested(!showInterested)}
            className={showInterested ? "bg-yellow-500 hover:bg-yellow-600 text-white" : ""}
          >
            <Star className={`w-4 h-4 ${showInterested ? 'fill-current' : ''}`} />
          </Button>
          
          {/* Add Client Button */}
          <Button variant="outline" size="sm" onClick={onNavigateToAddClient}>
            <Plus className="w-4 h-4" />
          </Button>
        </div>
        
        {/* Fixed Client Type Tabs */}
        <Tabs value={activeTab} onValueChange={(value) => setActiveTab(value as 'POTENTIAL' | 'EXISTING')}>
          <TabsList className="w-full">
            <TabsTrigger value="POTENTIAL" className="flex-1">Potential</TabsTrigger>
            <TabsTrigger value="EXISTING" className="flex-1">Existing</TabsTrigger>
          </TabsList>
        </Tabs>
      </div>

      {/* Scrollable Clients List */}
      <div key={refreshKey} className="flex-1 overflow-y-auto min-h-0">
        {filteredClients.map((client) => (
          <button
            key={client.id}
            onClick={() => onClientSelect(client)}
            className="w-full flex items-center px-4 py-3 border-b border-gray-100 hover:bg-gray-50 transition-colors text-left"
          >
            <div className="flex-1">
              <div className="flex items-center justify-between">
                <span className="text-black text-sm">{client.name}</span>
                <Badge 
                  variant={client.latestTouchpointReason === 'INTERESTED' ? 'default' : 'secondary'}
                  className={`text-xs flex items-center gap-1 ${
                    client.latestTouchpointReason === 'INTERESTED' 
                      ? 'bg-yellow-500 text-white hover:bg-yellow-600' 
                      : client.latestTouchpointReason === 'NOT INTERESTED'
                      ? 'bg-red-500 text-white'
                      : ''
                  }`}
                >
                  {client.latestTouchpointNumber && client.latestTouchpointNumber > 0 ? (
                    <>
                      {getTouchpointIcon(client.latestTouchpointNumber)}
                      <span>{getOrdinal(client.latestTouchpointNumber)}</span>
                      <span>•</span>
                    </>
                  ) : null}
                  <span>{client.remarks}</span>
                </Badge>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-gray-600 text-xs">{client.productType}</span>
                {client.latestTouchpointDate && (
                  <span className="text-gray-500 text-xs">{formatDate(client.latestTouchpointDate)}</span>
                )}
              </div>
            </div>
          </button>
        ))}
      </div>

      {/* Bottom Navigation - Fixed */}

    </div>
  );
}