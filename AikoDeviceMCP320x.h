#ifndef AikoDeviceMCP320x_h
#define AikoDeviceMCP320x_h

namespace Aiko {
  namespace Device {

    class SPIMaster;

    class MCP320x {
      public:
        MCP320x(SPIMaster& spiMaster, unsigned char slaveSelectPin);
        void setup();
        unsigned int readChannel(unsigned char channel);
      
      private:
        void select();
        void deselect();
  
        SPIMaster*    spiMaster_;       
        unsigned char slaveSelectPin_;
    };

  };
};

#endif
