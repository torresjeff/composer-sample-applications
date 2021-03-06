#!/bin/bash

# Exit on first error, print all commands.
set -ev


# Grab the root (parent) directory.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"


docker rm -f $(docker ps -aq) || true

# Install cli
npm install -g composer-cli

cd "$DIR"

TMP=$DIR/tmp

mkdir -p "$TMP"

cd "$TMP"

git clone "$(git rev-parse --show-toplevel)" composer-sample-applications

GETTING_STARTED=$TMP/composer-sample-applications/packages/getting-started

cd "$GETTING_STARTED"

npm install

npm test

composer network list -n digitalproperty-network --enrollId WebAppAdmin --enrollSecret DJY27pEnl16d

# Leave Composer-GettingStarted back to tmp
cd "$TMP"

git clone https://github.com/hyperledger/composer-sample-networks

cd "$TMP/composer-sample-networks/packages/digitalproperty-network"

npm install

TRANSACTION_FILE=$TMP/composer-sample-networks/packages/digitalproperty-network/lib/DigitalLandTitle.js

rm "$TRANSACTION_FILE"

touch "$TRANSACTION_FILE"

cat <<EOF > "$TRANSACTION_FILE"
/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

'use strict';

/** Process a property that is held for sale
 * @param {net.biz.digitalPropertyNetwork.RegisterPropertyForSale} propertyForSale the property to be sold
 * @transaction
 */
function onRegisterPropertyForSale(propertyForSale) {
    console.log('### onRegisterPropertyForSale ' + propertyForSale.toString());
    propertyForSale.title.forSale = true;
    propertyForSale.title.information = propertyForSale.title.information + ' Updated at: ' + new Date().toDateString();

    return getAssetRegistry('net.biz.digitalPropertyNetwork.LandTitle').then(function(result) {
            return result.update(propertyForSale.title);
        }
    );
}
EOF

composer archive create --sourceType dir --sourceName . --archiveFile digitalproperty-network.bna

composer network update --archiveFile digitalproperty-network.bna  --enrollId WebAppAdmin --enrollSecret DJY27pEnl16d

npm test

cd "$GETTING_STARTED"

npm run submitTransaction

rm -rf "$TMP"
