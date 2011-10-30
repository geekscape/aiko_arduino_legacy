#ifndef AikoDeviceMCP320x_h
#define AikoDeviceMCP320x_h

namespace Aiko {
  namespace Device {

    class MCP320x {
      public:
        MCP320x(unsigned char slaveSelectPin);
        unsigned int readChannel(unsigned char channel);

      private:
        void setup();

        unsigned char slaveSelectPin_;
        bool          isSetUp_;
    };

  };
};

#endif
