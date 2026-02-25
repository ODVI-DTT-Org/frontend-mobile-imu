import { useState } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogTrigger } from "./ui/dialog";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./ui/select";
import { Plus } from "lucide-react";
import { DataService } from "../services/DataService";
import { toast } from "sonner@2.0.3";

interface AddClientModalProps {
  onClientAdded?: () => void;
}

export function AddClientModal({ onClientAdded }: AddClientModalProps) {
  const [open, setOpen] = useState(false);
  const [formData, setFormData] = useState({
    fullName: "",
    productType: "",
    marketType: "",
    clientType: "POTENTIAL",
    pensionType: "",
    age: "",
    birthday: "",
    gmail: "",
    facebookLink: "",
    street: "",
    municipality: "",
    province: "",
    phoneNumber: ""
  });

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    // Validate required fields
    const requiredFields = [
      'fullName', 'productType', 'marketType', 'pensionType', 
      'age', 'birthday', 'phoneNumber', 'street', 'municipality', 'province'
    ];
    
    for (const field of requiredFields) {
      if (!formData[field as keyof typeof formData]) {
        toast.error(`${field.replace(/([A-Z])/g, ' $1').toLowerCase()} is required`);
        return;
      }
    }

    // Validate age is a number
    const age = parseInt(formData.age);
    if (isNaN(age) || age < 0 || age > 120) {
      toast.error("Please enter a valid age");
      return;
    }

    // Validate phone number format (Philippine mobile number)
    if (!/^09\d{9}$/.test(formData.phoneNumber)) {
      toast.error("Please enter a valid Philippine mobile number (09XXXXXXXXX)");
      return;
    }

    try {
      // Add client
      DataService.addClient({
        ...formData,
        age
      });
      
      toast.success("Client added successfully!");
      
      // Reset form
      setFormData({
        fullName: "",
        productType: "",
        marketType: "",
        clientType: "POTENTIAL",
        pensionType: "",
        age: "",
        birthday: "",
        gmail: "",
        facebookLink: "",
        street: "",
        municipality: "",
        province: "",
        phoneNumber: ""
      });
      
      // Close modal
      setOpen(false);
      
      // Notify parent component
      onClientAdded?.();
      
    } catch (error) {
      toast.error("Failed to add client. Please try again.");
    }
  };

  const marketTypes = DataService.getMarketTypes();
  const productTypes = DataService.getProductTypes();
  const pensionTypes = DataService.getPensionTypes();

  return (
    <>
      <Button 
        variant="outline" 
        size="sm" 
        onClick={() => {
          console.log("Add client button clicked");
          setOpen(true);
        }}
      >
        <Plus className="w-4 h-4" />
      </Button>
      
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="w-[340px] max-h-[90vh] overflow-y-auto p-4">
        <DialogHeader className="pb-4">
          <DialogTitle className="text-lg text-center">Add New Client</DialogTitle>
          <DialogDescription className="text-center text-sm text-muted-foreground">
            Fill out the form below to add a new client
          </DialogDescription>
        </DialogHeader>
        
        <form onSubmit={handleSubmit} className="space-y-5">
          {/* Personal Information */}
          <div className="bg-gray-50 rounded-lg p-3 space-y-3">
            <h3 className="text-sm font-semibold text-gray-800 border-b border-gray-200 pb-2">Personal Information</h3>
            
            <div>
              <Label htmlFor="fullName" className="text-xs text-gray-600">Full Name *</Label>
              <Input
                id="fullName"
                placeholder="LAST NAME, FIRST NAME M.I."
                value={formData.fullName}
                onChange={(e) => handleInputChange('fullName', e.target.value.toUpperCase())}
                className="mt-1 h-9 text-sm"
                required
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <Label htmlFor="age" className="text-xs text-gray-600">Age *</Label>
                <Input
                  id="age"
                  type="number"
                  placeholder="Age"
                  value={formData.age}
                  onChange={(e) => handleInputChange('age', e.target.value)}
                  className="mt-1 h-9 text-sm"
                  min="0"
                  max="120"
                  required
                />
              </div>
              <div>
                <Label htmlFor="birthday" className="text-xs text-gray-600">Birthday *</Label>
                <Input
                  id="birthday"
                  type="date"
                  value={formData.birthday}
                  onChange={(e) => handleInputChange('birthday', e.target.value)}
                  className="mt-1 h-9 text-sm"
                  required
                />
              </div>
            </div>

            <div>
              <Label htmlFor="phoneNumber" className="text-xs text-gray-600">Phone Number *</Label>
              <Input
                id="phoneNumber"
                placeholder="09XXXXXXXXX"
                value={formData.phoneNumber}
                onChange={(e) => handleInputChange('phoneNumber', e.target.value)}
                pattern="09\d{9}"
                maxLength={11}
                className="mt-1 h-9 text-sm"
                required
              />
            </div>

            <div>
              <Label htmlFor="gmail" className="text-xs text-gray-600">Email</Label>
              <Input
                id="gmail"
                type="email"
                placeholder="email@gmail.com"
                value={formData.gmail}
                onChange={(e) => handleInputChange('gmail', e.target.value)}
                className="mt-1 h-9 text-sm"
              />
            </div>

            <div>
              <Label htmlFor="facebookLink" className="text-xs text-gray-600">Facebook Link</Label>
              <Input
                id="facebookLink"
                placeholder="facebook.com/username"
                value={formData.facebookLink}
                onChange={(e) => handleInputChange('facebookLink', e.target.value)}
                className="mt-1 h-9 text-sm"
              />
            </div>
          </div>

          {/* Address Information */}
          <div className="bg-blue-50 rounded-lg p-3 space-y-3">
            <h3 className="text-sm font-semibold text-gray-800 border-b border-blue-200 pb-2">Address Information</h3>
            
            <div>
              <Label htmlFor="street" className="text-xs text-gray-600">Street *</Label>
              <Input
                id="street"
                placeholder="Purok 1, Brgy. Example"
                value={formData.street}
                onChange={(e) => handleInputChange('street', e.target.value)}
                className="mt-1 h-9 text-sm"
                required
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <Label htmlFor="municipality" className="text-xs text-gray-600">Municipality *</Label>
                <Input
                  id="municipality"
                  placeholder="City/Municipality"
                  value={formData.municipality}
                  onChange={(e) => handleInputChange('municipality', e.target.value)}
                  className="mt-1 h-9 text-sm"
                  required
                />
              </div>
              <div>
                <Label htmlFor="province" className="text-xs text-gray-600">Province *</Label>
                <Input
                  id="province"
                  placeholder="Province"
                  value={formData.province}
                  onChange={(e) => handleInputChange('province', e.target.value)}
                  className="mt-1 h-9 text-sm"
                  required
                />
              </div>
            </div>
          </div>

          {/* Client Classification */}
          <div className="bg-green-50 rounded-lg p-3 space-y-3">
            <h3 className="text-sm font-semibold text-gray-800 border-b border-green-200 pb-2">Client Classification</h3>
            
            <div>
              <Label htmlFor="clientType" className="text-xs text-gray-600">Client Type *</Label>
              <Select value={formData.clientType} onValueChange={(value) => handleInputChange('clientType', value)}>
                <SelectTrigger className="mt-1 h-9 text-sm">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="POTENTIAL">Potential</SelectItem>
                  <SelectItem value="EXISTING">Existing</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div>
              <Label htmlFor="marketType" className="text-xs text-gray-600">Market Type *</Label>
              <Select value={formData.marketType} onValueChange={(value) => handleInputChange('marketType', value)}>
                <SelectTrigger className="mt-1 h-9 text-sm">
                  <SelectValue placeholder="Select market type" />
                </SelectTrigger>
                <SelectContent>
                  {marketTypes.map(type => (
                    <SelectItem key={type} value={type}>{type}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div>
              <Label htmlFor="productType" className="text-xs text-gray-600">Product Type *</Label>
              <Select value={formData.productType} onValueChange={(value) => handleInputChange('productType', value)}>
                <SelectTrigger className="mt-1 h-9 text-sm">
                  <SelectValue placeholder="Select product type" />
                </SelectTrigger>
                <SelectContent>
                  {productTypes.map(type => (
                    <SelectItem key={type} value={type}>{type}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div>
              <Label htmlFor="pensionType" className="text-xs text-gray-600">Pension Type *</Label>
              <Select value={formData.pensionType} onValueChange={(value) => handleInputChange('pensionType', value)}>
                <SelectTrigger className="mt-1 h-9 text-sm">
                  <SelectValue placeholder="Select pension type" />
                </SelectTrigger>
                <SelectContent>
                  {pensionTypes.map(type => (
                    <SelectItem key={type} value={type}>{type}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="flex space-x-3 pt-4 border-t border-gray-200">
            <Button 
              type="button" 
              variant="outline" 
              onClick={() => setOpen(false)} 
              className="flex-1 h-10 text-sm"
            >
              Cancel
            </Button>
            <Button 
              type="submit" 
              className="flex-1 h-10 text-sm bg-green-600 hover:bg-green-700"
            >
              Add Client
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
    </>
  );
}