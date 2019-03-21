/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
#pragma once

#if ENABLE(JIT)

#include "JITBitBinaryOpGenerator.h"

namespace JSC {

class JITRightShiftGenerator : public JITBitBinaryOpGenerator {
public:
    enum ShiftType {
        SignedShift,
        UnsignedShift
    };

    JITRightShiftGenerator(const SnippetOperand& leftOperand, const SnippetOperand& rightOperand,
        JSValueRegs result, JSValueRegs left, JSValueRegs right,
        FPRReg leftFPR, GPRReg scratchGPR, FPRReg scratchFPR, ShiftType type = SignedShift)
        : JITBitBinaryOpGenerator(leftOperand, rightOperand, result, left, right, scratchGPR)
        , m_shiftType(type)
        , m_leftFPR(leftFPR)
        , m_scratchFPR(scratchFPR)
    { }

    void generateFastPath(CCallHelpers&);

private:
    ShiftType m_shiftType;
    FPRReg m_leftFPR;
    FPRReg m_scratchFPR;
};

} // namespace JSC

#endif // ENABLE(JIT)
