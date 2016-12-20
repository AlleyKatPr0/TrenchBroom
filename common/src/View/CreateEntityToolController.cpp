/*
 Copyright (C) 2010-2016 Kristian Duske
 
 This file is part of TrenchBroom.
 
 TrenchBroom is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 TrenchBroom is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with TrenchBroom. If not, see <http://www.gnu.org/licenses/>.
 */

#include "CreateEntityToolController.h"

#include "View/CreateEntityTool.h"
#include "View/InputState.h"

#include <cassert>

namespace TrenchBroom {
    namespace View {
        CreateEntityToolController::CreateEntityToolController(CreateEntityTool* tool) :
        m_tool(tool) {
            ensure(m_tool != NULL, "tool is null");
        }
        
        CreateEntityToolController::~CreateEntityToolController() {}
        
        Tool* CreateEntityToolController::doGetTool() {
            return m_tool;
        }
        
        bool CreateEntityToolController::doDragEnter(const InputState& inputState, const String& payload) {
            const StringList parts = StringUtils::split(payload, ':');
            if (parts.size() != 2)
                return false;
            if (parts[0] != "entity")
                return false;
            
            if (m_tool->createEntity(parts[1])) {
                doUpdateEntityPosition(inputState);
                return true;
            }
            return false;
        }
        
        bool CreateEntityToolController::doDragMove(const InputState& inputState) {
            doUpdateEntityPosition(inputState);
            return true;
        }
        
        void CreateEntityToolController::doDragLeave(const InputState& inputState) {
            m_tool->removeEntity();
        }
        
        bool CreateEntityToolController::doDragDrop(const InputState& inputState) {
            m_tool->commitEntity();
            return true;
        }
        
        bool CreateEntityToolController::doCancel() {
            return false;
        }

        CreateEntityToolController2D::CreateEntityToolController2D(CreateEntityTool* tool) :
        CreateEntityToolController(tool) {}
        
        void CreateEntityToolController2D::doUpdateEntityPosition(const InputState& inputState) {
            m_tool->updateEntityPosition2D(inputState.pickRay());
        }
        
        CreateEntityToolController3D::CreateEntityToolController3D(CreateEntityTool* tool) :
        CreateEntityToolController(tool) {}
        
        void CreateEntityToolController3D::doUpdateEntityPosition(const InputState& inputState) {
            m_tool->updateEntityPosition3D(inputState.pickRay(), inputState.pickResult());
        }
    }
}
