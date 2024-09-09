namespace PSAdapter
{    
    using System;
    using System.Collections.Generic;
    using System.Text;
    using System.Management.Automation;
    using Microsoft.PowerShell.Cmdletization;
    using System.Collections;
    using System.Collections.ObjectModel;
    using System.Reflection;
    using System.Collections.Specialized;
    using System.Management.Automation.Runspaces;
    using System.Text.RegularExpressions;

    public class PSTestStaticAdapter : CmdletAdapter<Object>
    {              
        public override void ProcessRecord(MethodInvocationInfo methodInvocationInfo)
        {
            PSObject methodInfoObject = new PSObject(methodInvocationInfo);
            this.Cmdlet.WriteObject(methodInfoObject);
        }                            
    }
}
