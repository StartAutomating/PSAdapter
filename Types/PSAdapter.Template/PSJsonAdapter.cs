namespace PSAdapter
{    
    using System;
    using System.Text;
    using System.Collections.Generic;    
    using System.Collections.ObjectModel;
    using System.Collections.Specialized;
    using System.Management.Automation;
    using Microsoft.PowerShell.Cmdletization;
    using System.Collections;    
    using System.Reflection;    
    using System.Management.Automation.Runspaces;
    using System.Text.RegularExpressions;
    using System.Threading;
    using System.Threading.Tasks;

    public class PSJsonAdapter : CmdletAdapter<Object>
    {
        public static OrderedDictionary GetMethodDictionary(MethodInvocationInfo methodInvocationInfo)
        {
            OrderedDictionary methodInfo = new OrderedDictionary(StringComparer.OrdinalIgnoreCase);
            foreach (var paramInfo in methodInvocationInfo.Parameters)
            {
                if (paramInfo.Value != null) {
                    methodInfo.Add(paramInfo.Name, paramInfo.Value);
                }                
            }
            return methodInfo;
        }                

        public PSObject GetMethodObject(MethodInvocationInfo methodInvocationInfo)
        {
            OrderedDictionary methodInfo = GetMethodDictionary(methodInvocationInfo);
            PSObject methodInfoObject = new PSObject(methodInfo);
            methodInfoObject.TypeNames.Clear();
            List<string> coalescedTypeNames = new List<string>();
            if (! string.IsNullOrEmpty(this.ClassName)) {
                coalescedTypeNames.Add(this.ClassName);
            }
            if (! string.IsNullOrEmpty(methodInvocationInfo.MethodName)) {
                coalescedTypeNames.Add(methodInvocationInfo.MethodName);
            }
            if (! string.IsNullOrEmpty(this.Cmdlet.ParameterSetName)) {
                coalescedTypeNames.Add(this.Cmdlet.ParameterSetName);
            }
            string joined = string.Join(".", coalescedTypeNames.ToArray());

            methodInfoObject.TypeNames.Add(joined);
            return methodInfoObject;

        }

        public override void ProcessRecord(MethodInvocationInfo methodInvocationInfo)
        {
            PowerShell psCmd = PowerShell.Create(RunspaceMode.CurrentRunspace);
            psCmd.AddCommand("ConvertTo-Json");
            psCmd.AddParameter("InputObject", GetMethodObject(methodInvocationInfo));
            foreach (PSObject result in psCmd.Invoke())
            {
                this.Cmdlet.WriteObject(result);
            }
        }                            
    }
}
