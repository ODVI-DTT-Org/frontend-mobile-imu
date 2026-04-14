import { useState, useMemo } from "react";
import { Calendar, MapPin, Phone, Clock, User, X } from "lucide-react";
import { MobileStatusBar } from "./MobileStatusBar";
import { Badge } from "./ui/badge";
import { Calendar as CalendarComponent } from "./ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "./ui/popover";
import { DataService, Visit, ClientDetails } from "../services/DataService";

interface MobileItineraryProps {}

interface ScheduledVisit extends Visit {
  clientName: string;
  clientPhone: string;
  isUpcoming: boolean;
  dayStatus: 'today' | 'tomorrow' | 'this-week' | 'future' | 'past';
}

export function MobileItinerary({}: MobileItineraryProps) {
  const [selectedFilter, setSelectedFilter] = useState<'yesterday' | 'today' | 'tomorrow'>('tomorrow');
  const [selectedDate, setSelectedDate] = useState<Date | undefined>();
  const [isCalendarOpen, setIsCalendarOpen] = useState(false);
  const [isCalendarMode, setIsCalendarMode] = useState(false);

  // Get all visits with client information
  const scheduledVisits = useMemo(() => {
    const allClients = DataService.getAllClientDetails();
    // For demo purposes, set today as September 8, 2025
    const today = new Date('2025-09-08');
    today.setHours(0, 0, 0, 0);
    
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const visits: ScheduledVisit[] = [];

    allClients.forEach(client => {
      // For scheduled visits (NextVisitDate)
      client.visits.forEach(visit => {
        if (visit.NextVisitDate) {
          const visitDate = new Date(visit.NextVisitDate);
          visitDate.setHours(0, 0, 0, 0);
          
          let dayStatus: 'today' | 'tomorrow' | 'this-week' | 'future' | 'past';
          const isUpcoming = visitDate >= today;
          
          if (visitDate.getTime() === yesterday.getTime()) {
            dayStatus = 'past';
          } else if (visitDate.getTime() === today.getTime()) {
            dayStatus = 'today';
          } else if (visitDate.getTime() === tomorrow.getTime()) {
            dayStatus = 'tomorrow';
          } else if (visitDate >= today) {
            dayStatus = 'future';
          } else {
            dayStatus = 'past';
          }

          const primaryPhone = client.phoneNumbers.find(p => p.IsPrimary)?.PhoneNumber || 
                             client.phoneNumbers[0]?.PhoneNumber || '';

          visits.push({
            ...visit,
            clientName: client.FullName,
            clientPhone: primaryPhone,
            isUpcoming,
            dayStatus
          });
        }
      });

      // For completed visits (DateOfVisit) - include yesterday's, today's completed, and tomorrow's if any
      client.visits.forEach(visit => {
        const visitDate = new Date(visit.DateOfVisit);
        visitDate.setHours(0, 0, 0, 0);
        
        let dayStatus: 'today' | 'tomorrow' | 'this-week' | 'future' | 'past';
        const isUpcoming = false; // These are completed visits
        
        if (visitDate.getTime() === yesterday.getTime()) {
          dayStatus = 'past';
        } else if (visitDate.getTime() === today.getTime()) {
          dayStatus = 'today';
        } else if (visitDate.getTime() === tomorrow.getTime()) {
          dayStatus = 'tomorrow';
        } else {
          return; // Skip visits that are not within our 3-day window
        }

        const primaryPhone = client.phoneNumbers.find(p => p.IsPrimary)?.PhoneNumber || 
                           client.phoneNumbers[0]?.PhoneNumber || '';

        visits.push({
          ...visit,
          clientName: client.FullName,
          clientPhone: primaryPhone,
          isUpcoming,
          dayStatus
        });
      });
    });

    // Sort by date
    return visits.sort((a, b) => {
      const dateA = new Date(a.NextVisitDate || a.DateOfVisit);
      const dateB = new Date(b.NextVisitDate || b.DateOfVisit);
      return dateA.getTime() - dateB.getTime();
    });
  }, []);

  // Filter visits based on selected filter
  const filteredVisits = useMemo(() => {
    // For demo purposes, set today as September 8, 2025
    const today = new Date('2025-09-08');
    today.setHours(0, 0, 0, 0);
    
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    switch (selectedFilter) {
      case 'yesterday':
        return scheduledVisits.filter(visit => {
          // For yesterday, prioritize completed visits (DateOfVisit)
          const visitDate = new Date(visit.DateOfVisit || visit.NextVisitDate);
          visitDate.setHours(0, 0, 0, 0);
          return visitDate.getTime() === yesterday.getTime();
        });
      case 'today':
        return scheduledVisits.filter(visit => {
          const visitDate = new Date(visit.NextVisitDate || visit.DateOfVisit);
          visitDate.setHours(0, 0, 0, 0);
          return visitDate.getTime() === today.getTime();
        });
      case 'tomorrow':
        return scheduledVisits.filter(visit => {
          const visitDate = new Date(visit.NextVisitDate || visit.DateOfVisit);
          visitDate.setHours(0, 0, 0, 0);
          return visitDate.getTime() === tomorrow.getTime();
        });
      default:
        return scheduledVisits;
    }
  }, [scheduledVisits, selectedFilter]);

  // Generate dummy visits for calendar mode
  const generateDummyVisitsForDate = (date: Date): ScheduledVisit[] => {
    const dateString = date.toISOString().split('T')[0];
    const allClients = DataService.getAllClientDetails();
    
    // Get two random clients for dummy visits
    const client1 = allClients[Math.floor(Math.random() * allClients.length)];
    const client2 = allClients[Math.floor(Math.random() * allClients.length)];
    
    const reasons = ['INTERESTED', 'NOT INTERESTED', 'UNDECIDED', 'LOAN INQUIRY', 'FOR UPDATE', 'FOR VERIFICATION'];
    
    return [
      {
        VisitID: 9000 + Math.floor(Math.random() * 1000),
        ClientID: client1.ClientID,
        DateOfVisit: dateString,
        Address: client1.addresses[0]?.Street + ", " + client1.addresses[0]?.Municipality || "Address not available",
        Touchpoint: Math.floor(Math.random() * 7) + 1,
        TouchpointType: 'Visit',
        ClientType: client1.ClientType,
        Reason: reasons[Math.floor(Math.random() * reasons.length)],
        TimeArrival: "09:00",
        OdometerArrival: Math.random() > 0.5 ? String(Math.floor(Math.random() * 50000) + 10000) : "",
        TimeDeparture: "09:45",
        OdometerDeparture: Math.random() > 0.5 ? String(Math.floor(Math.random() * 50000) + 10000) : "",
        NextVisitDate: "",
        Remarks: "Generated visit for selected date",
        clientName: client1.FullName,
        clientPhone: client1.phoneNumbers.find(p => p.IsPrimary)?.PhoneNumber || client1.phoneNumbers[0]?.PhoneNumber || "",
        isUpcoming: date >= new Date('2025-09-08'),
        dayStatus: 'past' as const
      },
      {
        VisitID: 9000 + Math.floor(Math.random() * 1000),
        ClientID: client2.ClientID,
        DateOfVisit: dateString,
        Address: client2.addresses[0]?.Street + ", " + client2.addresses[0]?.Municipality || "Address not available",
        Touchpoint: Math.floor(Math.random() * 7) + 1,
        TouchpointType: 'Visit',
        ClientType: client2.ClientType,
        Reason: reasons[Math.floor(Math.random() * reasons.length)],
        TimeArrival: "14:30",
        OdometerArrival: Math.random() > 0.5 ? String(Math.floor(Math.random() * 50000) + 10000) : "",
        TimeDeparture: "15:15",
        OdometerDeparture: Math.random() > 0.5 ? String(Math.floor(Math.random() * 50000) + 10000) : "",
        NextVisitDate: "",
        Remarks: "Generated visit for selected date",
        clientName: client2.FullName,
        clientPhone: client2.phoneNumbers.find(p => p.IsPrimary)?.PhoneNumber || client2.phoneNumbers[0]?.PhoneNumber || "",
        isUpcoming: date >= new Date('2025-09-08'),
        dayStatus: 'past' as const
      }
    ];
  };

  // Get visits to display (either filtered visits or calendar mode visits)
  const visitsToDisplay = useMemo(() => {
    if (isCalendarMode && selectedDate) {
      return generateDummyVisitsForDate(selectedDate);
    }
    return filteredVisits;
  }, [isCalendarMode, selectedDate, filteredVisits]);

  const handleDateSelect = (date: Date | undefined) => {
    if (date) {
      setSelectedDate(date);
      setIsCalendarMode(true);
      setIsCalendarOpen(false);
    }
  };

  const handleExitCalendarMode = () => {
    setIsCalendarMode(false);
    setSelectedDate(undefined);
  };

  const formatSelectedDate = (date: Date) => {
    return date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric',
      year: 'numeric'
    });
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric',
      year: 'numeric'
    });
  };

  const formatTime = (timeString: string) => {
    if (!timeString) return '';
    return timeString;
  };

  const getReasonBadgeColor = (reason: string) => {
    switch (reason) {
      case 'INTERESTED':
        return 'bg-green-100 text-green-800';
      case 'NOT INTERESTED':
        return 'bg-red-100 text-red-800';
      case 'UNDECIDED':
        return 'bg-yellow-100 text-yellow-800';
      case 'LOAN INQUIRY':
        return 'bg-blue-100 text-blue-800';
      case 'FOR UPDATE':
        return 'bg-purple-100 text-purple-800';
      case 'FOR VERIFICATION':
        return 'bg-orange-100 text-orange-800';
      case 'FOR ADA COMPLIANCE':
        return 'bg-indigo-100 text-indigo-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getDayStatusText = (dayStatus: string) => {
    switch (dayStatus) {
      case 'today':
        return 'Today';
      case 'tomorrow':
        return 'Tomorrow';
      case 'this-week':
        return 'This Week';
      case 'future':
        return 'Upcoming';
      case 'past':
        return 'Past';
      default:
        return '';
    }
  };

  const getTouchpointTypeIcon = (type: string) => {
    return type === 'Visit' ? <MapPin className="w-4 h-4" /> : <Phone className="w-4 h-4" />;
  };

  const getTouchpointOrdinal = (touchpoint: number) => {
    const ordinals = ['', '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th', '10th'];
    return ordinals[touchpoint] || `${touchpoint}th`;
  };

  return (
    <div className="bg-white flex flex-col h-full overflow-hidden">
      <MobileStatusBar />
      
      {/* Header */}
      <div className="flex items-center justify-center px-4 py-3 border-b border-gray-200 flex-shrink-0">
        <h1 className="text-lg text-black">Itinerary</h1>
      </div>

      {/* Filter Tabs */}
      <div className="flex items-center justify-between px-4 py-3 border-b border-gray-200 flex-shrink-0">
        {isCalendarMode ? (
          // Calendar mode header
          <div className="flex items-center space-x-3 flex-1">
            <button
              onClick={handleExitCalendarMode}
              className="p-1 hover:bg-gray-100 rounded-full"
            >
              <X className="w-4 h-4 text-gray-600" />
            </button>
            <span className="text-sm text-gray-600">
              {selectedDate && formatSelectedDate(selectedDate)}
            </span>
          </div>
        ) : (
          // Normal tabs
          <div className="flex space-x-1 bg-gray-100 rounded-lg p-1">
            {[
              { key: 'tomorrow', label: 'Tomorrow' },
              { key: 'today', label: 'Today' },
              { key: 'yesterday', label: 'Yesterday' }
            ].map((filter) => (
              <button
                key={filter.key}
                onClick={() => setSelectedFilter(filter.key as any)}
                className={`px-3 py-1.5 text-sm rounded-md transition-colors ${
                  selectedFilter === filter.key
                    ? 'bg-white text-black shadow-sm'
                    : 'text-gray-600 hover:text-black'
                }`}
              >
                {filter.label}
              </button>
            ))}
          </div>
        )}
        
        {/* Calendar Button */}
        <Popover open={isCalendarOpen} onOpenChange={setIsCalendarOpen}>
          <PopoverTrigger asChild>
            <button className="p-2 hover:bg-gray-100 rounded-lg">
              <Calendar className="w-5 h-5 text-gray-600" />
            </button>
          </PopoverTrigger>
          <PopoverContent className="w-auto p-0" align="end">
            <CalendarComponent
              mode="single"
              selected={selectedDate}
              onSelect={handleDateSelect}
              initialFocus
            />
          </PopoverContent>
        </Popover>
      </div>

      {/* Visits List */}
      <div className="flex-1 overflow-y-auto min-h-0">
        {visitsToDisplay.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full text-gray-500">
            <Calendar className="w-12 h-12 mb-4" />
            <p className="text-lg">No scheduled visits</p>
            <p className="text-sm">
              {isCalendarMode 
                ? "No visits found for the selected date" 
                : "Your itinerary is empty for the selected filter"
              }
            </p>
          </div>
        ) : (
          <div className="p-4 space-y-4">
            {visitsToDisplay.map((visit) => {
              // Get client details for product and pension type
              const clientDetails = DataService.getClientDetails(visit.ClientID);
              
              return (
                <div key={visit.VisitID} className="bg-white border border-gray-200 rounded-lg p-4 shadow-sm">
                  {/* Date and Status Header */}
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center space-x-2">
                      <Calendar className="w-4 h-4 text-gray-500" />
                      <span className="text-sm text-gray-600">
                        {formatDate(visit.NextVisitDate || visit.DateOfVisit)}
                      </span>
                      <Badge 
                        variant="secondary" 
                        className={`text-xs ${
                          isCalendarMode 
                            ? 'bg-purple-100 text-purple-800'
                            : visit.dayStatus === 'today' 
                            ? 'bg-blue-100 text-blue-800' 
                            : visit.dayStatus === 'tomorrow'
                            ? 'bg-green-100 text-green-800'
                            : 'bg-gray-100 text-gray-600'
                        }`}
                      >
                        {isCalendarMode ? 'Selected Date' :
                         selectedFilter === 'yesterday' ? 'Completed' : 
                         selectedFilter === 'today' ? 'Today' :
                         selectedFilter === 'tomorrow' ? 'Scheduled' : getDayStatusText(visit.dayStatus)}
                      </Badge>
                    </div>
                    <div className="flex items-center space-x-1 text-gray-500">
                      <span className="text-xs">{getTouchpointOrdinal(visit.Touchpoint)}</span>
                      <MapPin className="w-4 h-4" />
                      <span className="text-xs">Visit</span>
                    </div>
                  </div>

                  {/* Client Information */}
                  <div className="space-y-2">
                    <div className="flex items-center space-x-2">
                      <User className="w-4 h-4 text-gray-500" />
                      <span className="font-medium text-black">{visit.clientName}</span>
                    </div>
                    
                    {/* Always show full address */}
                    <div className="flex items-center space-x-2">
                      <MapPin className="w-4 h-4 text-gray-500" />
                      <span className="text-sm text-gray-600">{visit.Address}</span>
                    </div>
                    
                    {(selectedFilter === 'yesterday' || isCalendarMode) && (
                      // For yesterday or calendar mode - show Product and Pension Type
                      <>
                        {clientDetails && (
                          <>
                            <div className="flex items-center space-x-2">
                              <div className="w-4 h-4 flex items-center justify-center">
                                <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                              </div>
                              <span className="text-sm text-gray-600">{clientDetails.ProductType}</span>
                            </div>
                            <div className="flex items-center space-x-2">
                              <div className="w-4 h-4 flex items-center justify-center">
                                <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                              </div>
                              <span className="text-sm text-gray-600">{clientDetails.PensionType}</span>
                            </div>
                          </>
                        )}
                      </>
                    )}
                  </div>

                  {/* Visit Details - Only show for yesterday and calendar mode */}
                  {(selectedFilter === 'yesterday' || isCalendarMode) && (
                    <div className="mt-3 pt-3 border-t border-gray-100">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center space-x-2">
                          <Badge className={`text-xs ${getReasonBadgeColor(visit.Reason)}`}>
                            {visit.Reason}
                          </Badge>
                        </div>
                        {(visit.TimeArrival || visit.TimeDeparture) && (
                          <div className="flex items-center space-x-1 text-gray-500">
                            <Clock className="w-3 h-3" />
                            <span className="text-xs">
                              {visit.TimeDeparture 
                                ? `${visit.TimeArrival || 'N/A'} - ${visit.TimeDeparture}`
                                : formatTime(visit.TimeArrival)
                              }
                            </span>
                          </div>
                        )}
                      </div>
                      
                      {visit.Remarks && (
                        <p className="text-sm text-gray-600 mt-2 italic">"{visit.Remarks}"</p>
                      )}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>


    </div>
  );
}