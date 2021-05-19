function varargout = blockcat(varargin)
    %BLOCKCAT 
    %
    %  DM = BLOCKCAT({{DM}} v)
    %  SX = BLOCKCAT({{SX}} v)
    %  MX = BLOCKCAT({{MX}} v)
    %
    %
  [varargout{1:nargout}] = casadiMEX(867, varargin{:});
end
