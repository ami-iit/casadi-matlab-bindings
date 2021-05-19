function varargout = integrator_n_out(varargin)
    %INTEGRATOR_N_OUT Get the number of integrator outputs.
    %
    %  int = INTEGRATOR_N_OUT()
    %
    %
    %
    %
  [varargout{1:nargout}] = casadiMEX(784, varargin{:});
end
