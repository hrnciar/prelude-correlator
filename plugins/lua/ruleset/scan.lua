-- Copyright (C) 2006 G Ramon Gomez <gene at gomezbrothers dot com>
-- Copyright (C) 2008 PreludeIDS Technologies <info@prelude-ids.com>
-- All Rights Reserved.
--
-- This file is part of the Prelude-Correlator program.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2, or (at your option)
-- any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; see the file COPYING.  If not, write to
-- the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.


-- Detect Eventscan:
-- Playing multiple events from a single host against another single host

source = match("alert.source(*).node.address(*).address", "(.+)")
target = match("alert.target(*).node.address(*).address", "(.+)")

if source and target then
    for i, s in ipairs(source[1]) do for i, saddr in ipairs(s) do
        for i, t in ipairs(target[1]) do for i, daddr in ipairs(t) do
            ctx = Context.update("SCAN_EVENTSCAN_" .. saddr .. daddr, { expire = 60, threshold = 30 })

            ctx:set("alert.correlation_alert.alertident(>>).alertident", INPUT:get("alert.messageid"))
            ctx:set("alert.correlation_alert.alertident(-1).analyzerid", INPUT:get("alert.analyzer(-1).analyzerid"))
            ctx:set("alert.source(>>)", INPUT:get("alert.source"))
            ctx:set("alert.target(>>)", INPUT:get("alert.target"))

            if ctx:CheckAndDecThreshold("SCAN_EVENTSCAN_" .. saddr .. daddr) then
                ctx:set("alert.correlation_alert.name", "A single host has played many events against a single target. This may be a vulnerability scan")
                ctx:set("alert.classification.text", "Eventscan")
                ctx:set("alert.assessment.impact.severity", "high")

                ctx:alert()
                ctx:del()
            end
        end end
    end end
end



-- Detect Eventsweep:
-- Playing the same event from a single host against multiple hosts

classification = INPUT:get("alert.classification.text")

if source and classification then
    for i, s in ipairs(source[1]) do for i, saddr in ipairs(s) do
        ctx = Context.update("SCAN_EVENTSWEEP_" .. classification .. saddr, { expire = 60, threshold = 30 })

        -- unique (partial implementation)
        --cur = ctx:get("alert.target(0).node.address(0).address")
        -- if INPUT:get("alert.target(*).node.address(*).address") not in cur then

        ctx:set("alert.source(>>)", INPUT:get("alert.source"))
        ctx:set("alert.target(>>)", INPUT:get("alert.target"))
        ctx:set("alert.correlation_alert.alertident(>>).alertident", INPUT:get("alert.messageid"))
        ctx:set("alert.correlation_alert.alertident(-1).analyzerid", INPUT:get("alert.analyzer(-1).analyzerid"))

        if ctx:CheckAndDecThreshold() then
            ctx:set("alert.correlation_alert.name", "A single host has played the same event against multiple targets. This may be a network scan for a specific vulnerability")
            ctx:set("alert.classification.text", "Eventsweep")
            ctx:set("alert.assessment.impact.severity", "high")
            ctx:alert()
            ctx:del()
        end
            -- end -- unique
    end end
end




-- Detect Eventstorm:
-- Playing excessive events by a single host
if source then
    for i, s in ipairs(source[1]) do for i, saddr in ipairs(s) do
        ctx = Context.update("SCAN_EVENTSTORM_" .. saddr, { expire = 120, threshold = 150 })

        ctx:set("alert.source(>>)", INPUT:get("alert.source"))
        ctx:set("alert.target(>>)", INPUT:get("alert.target"))
        ctx:set("alert.correlation_alert.alertident(>>).alertident", INPUT:get("alert.messageid"))
        ctx:set("alert.correlation_alert.alertident(-1).analyzerid", INPUT:get("alert.analyzer(-1).analyzerid"))

        if ctx:CheckAndDecThreshold() then
            ctx:set("alert.correlation_alert.name", "A single host is producing an unusual amount of events")
            ctx:set("alert.classification.text", "Eventstorm")
            ctx:set("alert.assessment.impact.severity", "high")
            ctx:alert()
            ctx:del()
        end
    end end
end