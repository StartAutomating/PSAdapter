/*
.SYNOPSIS
    This is a template for a CmdletAdapter that does nothing.
.DESCRIPTION
    This is a template for a CmdletAdapter that literally does nothing.

    This can be useful as a starting point for creating a new CmdletAdapter.
*/
namespace PSAdapter
{    
    using System;
    using Microsoft.PowerShell.Cmdletization;

    public class NullAdapter : CmdletAdapter<Object>
    {                
    
    }
}
