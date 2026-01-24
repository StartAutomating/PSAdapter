namespace PSAdapter
{    
    using System;
    using System.Collections;
    using System.Collections.Specialized;        
    using System.Management.Automation;        
    using Microsoft.PowerShell.Cmdletization;        
    
    public class PSDictionaryAdapter : CmdletAdapter<Object>
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

        public override void ProcessRecord(MethodInvocationInfo methodInvocationInfo)
        {
            OrderedDictionary methodInfo = GetMethodDictionary(methodInvocationInfo);
            PSObject methodInfoObject = new PSObject(methodInfo);
            methodInfoObject.Members.Add(new PSNoteProperty("MethodName", methodInvocationInfo.MethodName));
            this.Cmdlet.WriteObject(methodInfoObject);
        }                            
    }
}
