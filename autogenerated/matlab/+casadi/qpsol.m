function varargout = qpsol(varargin)
    %QPSOL 
    %
    %  Function = QPSOL(char name, char solver, struct:SX qp, struct opts)
    %  Function = QPSOL(char name, char solver, struct:MX qp, struct opts)
    %
    %
  [varargout{1:nargout}] = casadiMEX(786, varargin{:});
end
